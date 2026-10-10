import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/errors.dart';
import '../../core/reddit_url.dart';
import 'reddit_client.dart';

/// Reads a thread's public `.json` listing from inside an offscreen WebView.
///
/// Experimental (branch `feat/webview-json-fetch`): Reddit answers anonymous
/// `.json` requests with 403 unless the client first ran the JavaScript check
/// served with its pages, which a WebView does like any browser. The WebView
/// opens the thread page, then fetches the listing from that page so the
/// request carries the cookies Reddit just set.
class WebViewRedditClient implements RedditClient {
  WebViewRedditClient({this.timeout = const Duration(seconds: 25)});

  final Duration timeout;

  static const _channel = 'TldrListing';

  @override
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken}) async {
    final link = extractRedditUrl(url);
    if (link == null) {
      throw const ApiError(
          code: 'INVALID_URL', message: 'Not a Reddit URL', retryable: false);
    }
    final id = extractPostId(link);
    // Short `/s/` links are opened as is: the WebView follows the redirect.
    final start = id == null ? link : 'https://www.reddit.com/comments/$id/';
    final body = await _load(start, cancelToken);
    return parseThreadListing(decodeListingBody(body.status, body.text));
  }

  Future<({int status, String text})> _load(String start, CancelToken? cancelToken) {
    final done = Completer<({int status, String text})>();
    final controller = WebViewController();
    Timer? timer;
    Timer? ticker;
    String? pageUrl;
    var busy = false;
    var lastStatus = 0;

    void finish({({int status, String text})? result, Object? error}) {
      if (done.isCompleted) return;
      timer?.cancel();
      ticker?.cancel();
      if (error != null) {
        done.completeError(error);
      } else {
        done.complete(result!);
      }
      // WebViewController has no dispose(): blank it so Reddit's scripts stop.
      unawaited(controller.loadRequest(Uri.parse('about:blank')).catchError((_) {}));
    }

    void onListing(JavaScriptMessage message) {
      busy = false;
      if (done.isCompleted) return;
      final value = jsonDecode(message.message) as Map<String, dynamic>;
      final status = (value['status'] as num).toInt();
      final text = value['text'] as String;
      if (status == 0) return;
      lastStatus = status;
      // An HTML 403 means Reddit's check has not passed yet: the next try
      // runs once the check has reloaded the page.
      if (status == 403 && !_looksLikeJson(text)) return;
      finish(result: (status: status, text: text));
    }

    // Reddit's full thread page can take longer to finish loading than the
    // timeout, so the listing is also tried on a tick once a page has started.
    void tryListing() {
      final id = pageUrl == null ? null : extractPostId(pageUrl!);
      // Still on the short link: wait for the redirect to the post.
      if (busy || done.isCompleted || id == null) return;
      busy = true;
      final path = jsonEncode('/comments/$id.json?sort=top&limit=500&depth=4&raw_json=1');
      final script = 'fetch($path, {credentials: "include"})'
          '.then(r => r.text().then(t => '
          '$_channel.postMessage(JSON.stringify({status: r.status, text: t}))))'
          '.catch(() => $_channel.postMessage(\'{"status":0,"text":""}\'));';
      unawaited(controller.runJavaScript(script).catchError((_) => busy = false));
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(_channel, onMessageReceived: onListing)
      ..setNavigationDelegate(NavigationDelegate(
        // A navigation drops any fetch the previous page started.
        onPageStarted: (url) {
          pageUrl = url;
          busy = false;
          ticker ??= Timer.periodic(const Duration(seconds: 2), (_) => tryListing());
        },
        onPageFinished: (url) {
          pageUrl = url;
          tryListing();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? false) {
            finish(
                error: const ApiError(
                    code: 'NETWORK_ERROR', message: 'Network error', retryable: true));
          }
        },
      ));

    cancelToken?.whenCancel.then((_) => finish(error: ApiError.cancelled));
    timer = Timer(timeout, () {
      finish(
          error: lastStatus == 403
              ? LiveRedditClient.blockedError
              : const ApiError(
                  code: 'REDDIT_UNAVAILABLE', message: 'Reddit unavailable', retryable: true));
    });

    controller.loadRequest(Uri.parse(start)).catchError((Object _) => finish(
        error: const ApiError(
            code: 'REDDIT_UNAVAILABLE', message: 'WebView failed', retryable: true)));
    return done.future;
  }
}

bool _looksLikeJson(String text) {
  final t = text.trimLeft();
  return t.startsWith('[') || t.startsWith('{');
}

/// Maps a `.json` response to the listing, or to the same errors as
/// [LiveRedditClient] (404 → not found, JSON 403 → closed thread).
List<dynamic> decodeListingBody(int status, String text) {
  final Object? data;
  try {
    data = jsonDecode(text);
  } on FormatException {
    if (status == 403) throw LiveRedditClient.blockedError;
    throw const ApiError(
        code: 'REDDIT_UNAVAILABLE', message: 'Unexpected response', retryable: true);
  }
  if (status == 404 || (data is Map && data['error'] == 404)) {
    throw const ApiError(
        code: 'THREAD_NOT_FOUND', message: 'Thread not found', retryable: false);
  }
  if (status == 403 || (data is Map && data['error'] == 403)) {
    final reason = data is Map ? data['reason'] as String? : null;
    throw ApiError(
      code: 'THREAD_UNAVAILABLE',
      message: 'Forbidden',
      retryable: false,
      reason: switch (reason) {
        'quarantined' => 'quarantined',
        'banned' => 'banned',
        _ => 'private',
      },
    );
  }
  if (data is! List || data.length < 2) {
    throw const ApiError(
        code: 'THREAD_NOT_FOUND', message: 'Unexpected listing', retryable: false);
  }
  return data;
}
