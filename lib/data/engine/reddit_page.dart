import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/errors.dart';
import '../../core/reddit_url.dart';
import 'reddit_client.dart';
import 'thread_script.dart';

/// The thread read from inside the page, in the shape of Reddit's `.json`.
typedef ListingBody = ({int status, String text});

/// One Reddit thread opened in a WebView, from which the thread is read. The
/// Summary screen shows it while the thread loads; without a screen it runs
/// offscreen.
///
/// Reddit serves its pages only once the client ran the JavaScript check
/// they come with, which a WebView does like any browser. The thread is then
/// read from the page by [threadScript], with the cookies Reddit just set.
///
/// The page asks for Reddit's desktop site: to anonymous phones, Reddit only
/// serves a handful of comments and no way to load the rest.
class RedditPage {
  RedditPage() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_desktopUserAgent)
      ..addJavaScriptChannel(_channel, onMessageReceived: _onListing)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        // A navigation drops any fetch the previous page started.
        onPageStarted: (url) {
          _pageUrl = url;
          _busy = false;
        },
        // The cookie sheet shows up long before the page finishes loading.
        onProgress: (_) => _hideConsentSheet(),
        onPageFinished: (url) {
          _pageUrl = url;
          _hideConsentSheet();
          _tryListing();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? false) {
            _finish(
                error: const ApiError(
                    code: 'NETWORK_ERROR', message: 'Network error', retryable: true));
          }
        },
      ));
  }

  final controller = WebViewController();

  /// True once the listing was read: the Summary screen covers the page then.
  final listed = ValueNotifier(false);

  static const _channel = 'TldrListing';

  /// Any script on the page can call the channel: only messages carrying this
  /// page's nonce are our fetch's answer.
  final _nonce = List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16)).join();

  Completer<ListingBody>? _done;
  Timer? _timeout;
  Timer? _ticker;
  String? _pageUrl;
  String? _postId;
  var _busy = false;
  var _lastStatus = 0;

  /// Opens [start] (a post or short link) and reads its listing.
  Future<ListingBody> listing(String start,
      {CancelToken? cancelToken, Duration timeout = const Duration(seconds: 25)}) {
    _finish(error: ApiError.cancelled);
    _done?.future.ignore();
    final done = _done = Completer<ListingBody>();
    _postId = extractPostId(start);
    _lastStatus = 0;
    _busy = false;
    listed.value = false;
    // A late cancel or timeout from an earlier call must not end this one.
    void finishThis(ApiError error) {
      if (identical(_done, done)) _finish(error: error);
    }

    cancelToken?.whenCancel.then((_) => finishThis(ApiError.cancelled));
    _timeout = Timer(timeout, () {
      finishThis(_lastStatus == 403
          ? redditBlockedError
          : const ApiError(
              code: 'REDDIT_UNAVAILABLE', message: 'Reddit unavailable', retryable: true));
    });
    // Reddit's full thread page can take longer to finish loading than the
    // timeout, so the listing is also tried on a tick.
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      _hideConsentSheet();
      _tryListing();
    });
    controller.loadRequest(Uri.parse(start)).catchError((Object _) => _finish(
        error: const ApiError(
            code: 'REDDIT_UNAVAILABLE', message: 'WebView failed', retryable: true)));
    return done.future;
  }

  /// Stops Reddit's scripts (WebViewController has no dispose()).
  void close() {
    _finish(error: ApiError.cancelled);
    unawaited(controller.loadRequest(Uri.parse('about:blank')).catchError((_) {}));
  }

  /// Keeps the page on this thread: Reddit's check reloads it, a short link
  /// redirects to it, anything else (links, « open in app ») is blocked.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url == 'about:blank') return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    final host = uri?.host.toLowerCase() ?? '';
    final onReddit = uri != null &&
        uri.scheme == 'https' &&
        (host == 'reddit.com' || host.endsWith('.reddit.com'));
    if (!onReddit) return NavigationDecision.prevent;
    if (!request.isMainFrame || _postId == null) return NavigationDecision.navigate;
    final id = extractPostId(request.url);
    return id == null || id == _postId
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  /// Reddit's cookie sheet would cover the post for the few seconds it is on
  /// screen. Hiding it answers nothing: only essential cookies apply.
  void _hideConsentSheet() {
    const script = 'if (document.head && !document.getElementById("tldr-hide")) {'
        'const s = document.createElement("style"); s.id = "tldr-hide";'
        's.textContent = "#data-protection-consent-wrapper, #data-protection-consent-sheet,'
        ' #data-protection-consent-dialog { display: none !important; }";'
        'document.head.appendChild(s); }';
    unawaited(controller.runJavaScript(script).catchError((_) {}));
  }

  void _tryListing() {
    final done = _done;
    final id = _postId ?? (_pageUrl == null ? null : extractPostId(_pageUrl!));
    // Still on the short link: wait for the redirect to the post.
    if (_busy || done == null || done.isCompleted || id == null) return;
    _postId = id;
    _busy = true;
    final script = threadScript(channel: _channel, nonce: _nonce);
    unawaited(controller.runJavaScript(script).catchError((_) => _busy = false));
  }

  void _onListing(JavaScriptMessage message) {
    final Object? value;
    try {
      value = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (value is! Map || value['nonce'] != _nonce) return;
    _busy = false;
    final status = (value['status'] as num?)?.toInt() ?? 0;
    final text = value['text'] as String? ?? '';
    if (status == 0) return;
    _lastStatus = status;
    // A 403 without a listing means Reddit's check has not passed yet: the
    // next try runs once the check has reloaded the page.
    if (!_looksLikeJson(text)) return;
    _finish(result: (status: status, text: text));
  }

  void _finish({ListingBody? result, Object? error}) {
    final done = _done;
    if (done == null || done.isCompleted) return;
    _timeout?.cancel();
    _ticker?.cancel();
    if (error != null) {
      done.completeError(error);
    } else {
      done.complete(result!);
      // A 404 or a closed thread ends in an error, not under the dust.
      listed.value = result.status == 200;
    }
  }
}

/// The browser engine each platform's WebView runs, as a desktop browser.
String get _desktopUserAgent => defaultTargetPlatform == TargetPlatform.iOS
    ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/18.6 Safari/605.1.15'
    : 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36';

bool _looksLikeJson(String text) {
  final t = text.trimLeft();
  return t.startsWith('[') || t.startsWith('{');
}

/// The page the Summary screen is showing, if any: the Reddit client reads the
/// listing from it instead of opening a second, offscreen one.
class RedditPageHost {
  RedditPage? visible;
}
