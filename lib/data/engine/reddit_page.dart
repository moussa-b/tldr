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
    _ready = controller
        .getUserAgent()
        .then((ua) => desktopUserAgent(ua ?? ''), onError: (Object _) => desktopUserAgent(''))
        .then(controller.setUserAgent)
        .catchError((Object _) {});
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(_channel, onMessageReceived: _onListing)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        // A navigation drops any script the previous page started.
        onPageStarted: (url) {
          _pageUrl = url;
          _busy = false;
        },
        // The cookie sheet shows up long before the page finishes loading.
        onProgress: (_) => _hideConsentSheet(),
        onPageFinished: (url) {
          _pageUrl = url;
          // On iOS the previous page's script may have died unanswered.
          _busy = false;
          _hideConsentSheet();
          _tryListing();
        },
        onWebResourceError: (error) {
          // A navigation this page stopped (a comment's permalink) is not a
          // network error: NSURLErrorCancelled, WebKit's interrupted load.
          if (error.errorCode == -999 || error.errorCode == 102) return;
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
  /// listing's nonce are [threadScript]'s answer, so a late answer for an
  /// earlier listing is dropped too.
  var _nonce = '';

  /// The desktop user agent is set before the first page loads.
  late final Future<void> _ready;

  Completer<ListingBody>? _done;
  DateTime? _deadline;
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
    _nonce = List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
    _deadline = DateTime.now().add(timeout);
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
    _ready
        .then((_) => identical(_done, done) && !done.isCompleted
            ? controller.loadRequest(Uri.parse(start))
            : null)
        .catchError((Object _) => _finish(
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
  /// redirects to it, anything else (links, « open in app ») is blocked. A
  /// comment's permalink shows only that comment's replies: the whole thread
  /// is opened instead.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url == 'about:blank') return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    final host = uri?.host.toLowerCase() ?? '';
    final onReddit = uri != null &&
        uri.scheme == 'https' &&
        (host == 'reddit.com' || host.endsWith('.reddit.com'));
    if (!onReddit) return NavigationDecision.prevent;
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final id = extractPostId(request.url);
    // A short link may redirect to a comment, before the post id is known.
    if (id != null && (_postId == null || id == _postId) && isCommentPermalink(request.url)) {
      _postId = id;
      // After this navigation is stopped, not from inside its decision.
      Timer(Duration.zero, () {
        unawaited(controller
            .loadRequest(Uri.parse('https://www.reddit.com/comments/$id/?sort=top'))
            .catchError((_) {}));
      });
      return NavigationDecision.prevent;
    }
    return _postId == null || id == null || id == _postId
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
    // Room left for the answer to cross the channel before the timeout.
    final deadline = _deadline!.subtract(const Duration(milliseconds: 1500));
    final script = threadScript(
        channel: _channel,
        nonce: _nonce,
        postId: id,
        deadlineMs: deadline.millisecondsSinceEpoch);
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
    // The post is there: an earlier 403 was Reddit's check, not a refusal.
    if (status == 1) _lastStatus = 0;
    if (status <= 1) return;
    _lastStatus = status;
    // A 403 without a listing is Reddit's check, or Reddit refusing the read:
    // the next try runs once the check has reloaded the page, and the timeout
    // reports a refusal.
    if (!_looksLikeJson(text)) return;
    final failed = (value['failed'] as num?)?.toInt() ?? 0;
    if (failed > 0) debugPrint('RedditPage: $failed « more comments » blocks not loaded');
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

/// The WebView's own user agent ([mobile]) as the desktop browser of the same
/// engine and version: Safari on a Mac for WebKit, Chrome on Linux for
/// Chromium.
@visibleForTesting
String desktopUserAgent(String mobile) {
  final chrome = RegExp(r'Chrome/(\d+)').firstMatch(mobile)?.group(1);
  if (chrome != null) {
    return 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/$chrome.0.0.0 Safari/537.36';
  }
  final ios = RegExp(r'OS (\d+)_(\d+)').firstMatch(mobile);
  final safari = ios == null ? '18.6' : '${ios.group(1)}.${ios.group(2)}';
  return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/$safari Safari/605.1.15';
}

bool _looksLikeJson(String text) {
  final t = text.trimLeft();
  return t.startsWith('[') || t.startsWith('{');
}

/// The page the Summary screen is showing, if any: the Reddit client reads the
/// listing from it instead of opening a second, offscreen one.
class RedditPageHost {
  RedditPage? visible;
}
