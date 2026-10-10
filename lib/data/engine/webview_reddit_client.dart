import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/reddit_url.dart';
import 'reddit_client.dart';
import 'reddit_page.dart';

/// Reads a thread's public `.json` listing through a [RedditPage]: the one the
/// Summary screen shows if [host] has one, an offscreen page otherwise.
///
/// Experimental (branch `feat/webview-json-fetch`).
class WebViewRedditClient implements RedditClient {
  WebViewRedditClient({this.host, this.timeout = const Duration(seconds: 25)});

  final RedditPageHost? host;
  final Duration timeout;

  @override
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken}) async {
    final link = extractRedditUrl(url);
    if (link == null) {
      throw const ApiError(
          code: 'INVALID_URL', message: 'Not a Reddit URL', retryable: false);
    }
    final id = extractPostId(link);
    if (id == null && !isShortLink(link)) {
      throw const ApiError(
          code: 'UNSUPPORTED_URL', message: 'Not a post URL', retryable: false);
    }
    // Short `/s/` links are opened as is: the WebView follows the redirect.
    final start = id == null ? link : 'https://www.reddit.com/comments/$id/';
    final shared = host?.visible;
    final page = shared ?? RedditPage();
    try {
      final body = await page.listing(start, cancelToken: cancelToken, timeout: timeout);
      return parseThreadListing(decodeListingBody(body.status, body.text));
    } finally {
      if (shared == null) page.close();
    }
  }
}

/// Maps a `.json` response to the listing, or to the same errors as
/// the spec (404 → not found, JSON 403 → closed thread, HTML 403 → blocked).
List<dynamic> decodeListingBody(int status, String text) {
  final Object? data;
  try {
    data = jsonDecode(text);
  } on FormatException {
    if (status == 403) throw redditBlockedError;
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
