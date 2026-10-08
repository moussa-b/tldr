// ignore_for_file: avoid_print
// Live check of the Reddit side of DirectTldrApi (no AI key needed):
//   dart run tool/smoke_reddit.dart [reddit-url]
// Without an argument, takes the top post of r/AskReddit today.
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
  final client = LiveRedditClient(dio: dio, userAgent: _ua);
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
