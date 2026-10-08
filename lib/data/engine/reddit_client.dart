import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/reddit_url.dart';
import '../models/models.dart';
import 'comment_selector.dart';

/// A thread as fetched from Reddit, before AI analysis.
class RedditThread {
  const RedditThread({
    required this.thread,
    required this.selftext,
    required this.comments,
  });

  final Thread thread;
  final String selftext;
  final List<RawComment> comments;
}

/// Reads Reddit directly from the device (spec « Révision 2026-10-09 »).
abstract interface class RedditClient {
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken});
}

class LiveRedditClient implements RedditClient {
  LiveRedditClient({
    Dio? dio,
    this.clientId = '',
    String Function()? deviceId,
    this.userAgent = 'android:com.bdzapps.tldr:v1.0.0 (by /u/tldr_plus_app)',
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _deviceId = deviceId ?? (() => 'DO_NOT_TRACK_THIS_DEVICE');

  final Dio _dio;

  /// Reddit « installed app » client id; empty → public .json endpoints.
  final String clientId;
  final String Function() _deviceId;
  final String userAgent;

  String? _token;
  DateTime _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  static const _maxRedirects = 3;

  @override
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken}) async {
    final link = extractRedditUrl(url);
    if (link == null) {
      throw const ApiError(
          code: 'INVALID_URL', message: 'Not a Reddit URL', retryable: false);
    }
    final resolved = await _resolveShortLink(link, cancelToken);
    final id = extractPostId(resolved);
    if (id == null) {
      throw const ApiError(
          code: 'UNSUPPORTED_URL', message: 'Not a post URL', retryable: false);
    }
    final json = await _getThread(id, cancelToken);
    return parseThreadListing(json);
  }

  /// `/r/<sub>/s/<code>` share links redirect to the canonical post URL.
  Future<String> _resolveShortLink(String url, CancelToken? cancelToken) async {
    var current = url;
    for (var i = 0; i < _maxRedirects; i++) {
      final uri = Uri.parse(current);
      final isShort = uri.pathSegments.length >= 4 &&
          uri.pathSegments[0] == 'r' &&
          uri.pathSegments[2] == 's';
      if (!isShort) return current;
      try {
        final response = await _dio.get<dynamic>(
          current,
          options: Options(
            followRedirects: false,
            validateStatus: (s) => s != null && s < 500,
            headers: {'User-Agent': userAgent},
            responseType: ResponseType.plain,
          ),
          cancelToken: cancelToken,
        );
        if (response.statusCode == 403) throw blockedError;
        final location = response.headers.value('location');
        if (location == null) {
          throw const ApiError(
              code: 'THREAD_NOT_FOUND', message: 'Short link not resolved', retryable: false);
        }
        current = uri.resolve(location).toString();
      } on DioException catch (e) {
        throw _networkError(e);
      }
    }
    return current;
  }

  Future<List<dynamic>> _getThread(String id, CancelToken? cancelToken) async {
    final useOAuth = clientId.isNotEmpty;
    final url = useOAuth
        ? 'https://oauth.reddit.com/comments/$id'
        : 'https://www.reddit.com/comments/$id.json';
    final headers = <String, String>{'User-Agent': userAgent};
    if (useOAuth) headers['Authorization'] = 'Bearer ${await _accessToken()}';
    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: {'sort': 'top', 'limit': 500, 'depth': 4, 'raw_json': 1},
        options: Options(headers: headers, validateStatus: (s) => s == 200),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is! List || data.length < 2) {
        throw const ApiError(
            code: 'THREAD_NOT_FOUND', message: 'Unexpected listing', retryable: false);
      }
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw const ApiError(
            code: 'THREAD_NOT_FOUND', message: 'Thread not found', retryable: false);
      }
      if (status == 403) {
        final body = e.response?.data;
        final reason = body is Map ? body['reason'] as String? : null;
        // A JSON 403 names why the thread is closed; an HTML 403 is Reddit
        // blocking the client itself (anonymous access refused).
        if (reason == null) throw blockedError;
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
      throw _networkError(e);
    }
  }

  Future<String> _accessToken() async {
    if (_token != null && DateTime.now().isBefore(_tokenExpiry)) return _token!;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://www.reddit.com/api/v1/access_token',
        data: {
          'grant_type': 'https://oauth.reddit.com/grants/installed_client',
          'device_id': _deviceId(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': userAgent,
            // Installed apps have no secret: basic auth with an empty password.
            'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:'))}',
          },
        ),
      );
      final body = response.data!;
      _token = body['access_token'] as String;
      final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      return _token!;
    } on DioException catch (e) {
      throw _networkError(e);
    }
  }

  /// Reddit refused this client (seen on anonymous .json requests): only an
  /// OAuth client id fixes it, so retrying is pointless.
  static const blockedError = ApiError(
    code: 'REDDIT_UNAVAILABLE',
    message: 'Reddit blocked the request',
    retryable: false,
    reason: 'blocked',
  );

  ApiError _networkError(DioException e) {
    if (e.type == DioExceptionType.cancel) return ApiError.cancelled;
    return const ApiError(
        code: 'REDDIT_UNAVAILABLE', message: 'Reddit unavailable', retryable: true);
  }
}

/// Parses Reddit's `[postListing, commentListing]` response.
RedditThread parseThreadListing(List<dynamic> json) {
  final post = ((json[0] as Map)['data']['children'] as List).first['data'] as Map;
  final selftext = (post['selftext'] as String?) ?? '';
  final removedBy = post['removed_by_category'] as String?;
  final comments = <RawComment>[];
  _flatten((json[1] as Map)['data']['children'] as List, null, 0, comments);

  final usable = comments.where((c) => c.isUsable).length;
  final bodyGone = selftext == '[removed]' || selftext == '[deleted]';
  if ((removedBy != null || bodyGone) && usable == 0) {
    throw ApiError(
      code: 'THREAD_UNAVAILABLE',
      message: 'Thread removed',
      retryable: false,
      reason: removedBy == 'deleted' || selftext == '[deleted]' ? 'deleted' : 'removed',
    );
  }

  final subreddit = post['subreddit'] as String;
  final id = post['id'] as String;
  final permalink = post['permalink'] as String? ?? '/r/$subreddit/comments/$id/';
  final excerpt = selftext.isEmpty || bodyGone
      ? null
      : (selftext.length > 300 ? selftext.substring(0, 300) : selftext);

  return RedditThread(
    thread: Thread(
      id: id,
      subreddit: subreddit,
      title: post['title'] as String,
      author: (post['author'] as String?) ?? '[deleted]',
      permalink: 'https://www.reddit.com$permalink',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((post['created_utc'] as num) * 1000).round(),
          isUtc: true),
      score: (post['score'] as num).toInt(),
      upvoteRatio: ((post['upvote_ratio'] as num?) ?? 1).toDouble(),
      numComments: ((post['num_comments'] as num?) ?? 0).toInt(),
      isNsfw: (post['over_18'] as bool?) ?? false,
      selftextExcerpt: excerpt,
    ),
    selftext: bodyGone ? '' : selftext,
    comments: comments,
  );
}

void _flatten(List children, String? parentId, int depth, List<RawComment> out) {
  for (final child in children) {
    if (child is! Map || child['kind'] != 't1') continue;
    final data = child['data'] as Map;
    final id = data['id'] as String;
    out.add(RawComment(
      id: id,
      parentId: parentId,
      depth: depth,
      author: (data['author'] as String?) ?? '[deleted]',
      score: ((data['score'] as num?) ?? 0).toInt(),
      body: (data['body'] as String?) ?? '',
      stickied: (data['stickied'] as bool?) ?? false,
      distinguished: data['distinguished'] as String?,
    ));
    final replies = data['replies'];
    if (replies is Map && depth < 4) {
      _flatten(replies['data']['children'] as List, id, depth + 1, out);
    }
  }
}
