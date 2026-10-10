import 'package:dio/dio.dart';

import '../../core/errors.dart';
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

/// Reads one Reddit thread from the device (spec « Lecture de Reddit »).
abstract interface class RedditClient {
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken});
}

/// Reddit refused the client (its JavaScript check never passed): retrying
/// right away is pointless.
const redditBlockedError = ApiError(
  code: 'REDDIT_UNAVAILABLE',
  message: 'Reddit blocked the request',
  retryable: false,
  reason: 'blocked',
);

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
