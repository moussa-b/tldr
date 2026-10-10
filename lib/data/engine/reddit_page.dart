import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/errors.dart';
import '../../core/reddit_url.dart';
import 'reddit_client.dart';

/// A `.json` response read from inside the page.
typedef ListingBody = ({int status, String text});

/// One Reddit thread opened in a WebView, from which the `.json` listing is
/// read. The Summary screen shows it while the thread loads; without a screen
/// it runs offscreen.
///
/// Reddit answers anonymous `.json` requests with 403 unless the client first
/// ran the JavaScript check served with its pages, which a WebView does like
/// any browser. The listing is then fetched from the page, with the cookies
/// Reddit just set.
class RedditPage {
  RedditPage() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
    _done?.future.ignore();
    final done = _done = Completer<ListingBody>();
    _postId = extractPostId(start);
    _lastStatus = 0;
    listed.value = false;
    cancelToken?.whenCancel.then((_) => _finish(error: ApiError.cancelled));
    _timeout = Timer(timeout, () {
      _finish(
          error: _lastStatus == 403
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
    final path = jsonEncode('/comments/$id.json?sort=top&limit=500&depth=4&raw_json=1');
    final script = 'fetch($path, {credentials: "include"})'
        '.then(r => r.text().then(t => '
        '$_channel.postMessage(JSON.stringify({status: r.status, text: t}))))'
        '.catch(() => $_channel.postMessage(\'{"status":0,"text":""}\'));';
    unawaited(controller.runJavaScript(script).catchError((_) => _busy = false));
  }

  void _onListing(JavaScriptMessage message) {
    _busy = false;
    final value = jsonDecode(message.message) as Map<String, dynamic>;
    final status = (value['status'] as num).toInt();
    final text = value['text'] as String;
    if (status == 0) return;
    _lastStatus = status;
    // An HTML 403 means Reddit's check has not passed yet: the next try runs
    // once the check has reloaded the page.
    if (status == 403 && !_looksLikeJson(text)) return;
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

bool _looksLikeJson(String text) {
  final t = text.trimLeft();
  return t.startsWith('[') || t.startsWith('{');
}

/// The page the Summary screen is showing, if any: the Reddit client reads the
/// listing from it instead of opening a second, offscreen one.
class RedditPageHost {
  RedditPage? visible;
}
