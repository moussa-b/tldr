// ignore_for_file: avoid_print
// Live check of Reddit's OAuth access (no AI key needed). Reddit refuses
// anonymous clients, so an approved installed-app client id is required:
//   REDDIT_CLIENT_ID=<id> dart run tool/smoke_reddit.dart [reddit-url]
// Without a URL, takes the top post of r/AskReddit today.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tldr/data/engine/comment_selector.dart';
import 'package:tldr/data/engine/prompts.dart';
import 'package:tldr/data/engine/reddit_client.dart';

const _ua = 'android:com.bdzapps.tldr:v1.0.0 (smoke test)';

Future<void> main(List<String> args) async {
  final dio = Dio();
  var url = args.isEmpty ? null : args.first;
  if (url == null) {
    final top = await dio.get<Map<String, dynamic>>(
      'https://www.reddit.com/r/AskReddit/top.json',
      queryParameters: {'limit': 1, 't': 'day'},
      options: Options(headers: {'User-Agent': _ua}),
    );
    final post = (top.data!['data']['children'] as List).first['data'] as Map;
    url = 'https://www.reddit.com${post['permalink']}';
  }
  final client = LiveRedditClient(
      dio: dio, userAgent: _ua, clientId: Platform.environment['REDDIT_CLIENT_ID'] ?? '');
  final watch = Stopwatch()..start();
  final thread = await client.fetch(url);
  final selection = selectComments(thread.comments);
  final prompt = buildSummaryUserMessage(thread.thread, thread.selftext, selection);
  print('URL        : $url');
  print('Title      : ${thread.thread.title}');
  print('Subreddit  : r/${thread.thread.subreddit} (nsfw: ${thread.thread.isNsfw})');
  print('Comments   : ${thread.comments.length} fetched / ${thread.thread.numComments} total');
  print('Selected   : ${selection.analyzed} (+${selection.comments.length - selection.analyzed} placeholders), truncated: ${selection.truncated}');
  print('Prompt     : ${prompt.length} chars');
  print('Fetch time : ${watch.elapsedMilliseconds} ms');
}
