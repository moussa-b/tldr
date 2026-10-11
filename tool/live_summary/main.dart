// A command-line tool: its output is read by tool/live_summary.sh.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tldr/core/errors.dart';
import 'package:dio/dio.dart';
import 'package:tldr/data/engine/direct_tldr_api.dart';
import 'package:tldr/data/engine/reddit_client.dart';
import 'package:tldr/data/engine/reddit_page.dart';
import 'package:tldr/data/engine/webview_reddit_client.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/data/summary_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Real summary on a simulator or emulator: reads a thread through the
/// Reddit WebView, as the Summary screen does, and summarizes it with Gemini.
/// Run it with tool/live_summary.sh, which passes the keys and reads the
/// `LIVE_OK` / `LIVE_FAIL` line.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('THREAD_URL',
      defaultValue: 'https://www.reddit.com/r/founder/comments/1x1wi5n/someone_copied_my_saas/');
  const dumpPath = String.fromEnvironment('DUMP_LISTING');
  final keys = const String.fromEnvironment('GEMINI_KEYS')
      .split(',')
      .where((k) => k.trim().isNotEmpty)
      .toList();

  final page = RedditPage();
  final host = RedditPageHost()..visible = page;
  runApp(MaterialApp(home: Scaffold(body: SafeArea(child: WebViewWidget(controller: page.controller)))));

  try {
    if (keys.isEmpty) throw StateError('no GEMINI_KEYS');
    if (dumpPath.isNotEmpty) {
      final body = await page.listing(url);
      File(dumpPath).writeAsStringSync(body.text);
      print('LIVE_DUMP status=${body.status} bytes=${body.text.length}');
    }
    final watch = Stopwatch()..start();
    final api = DirectTldrApi(
      reddit: _TimedReddit(WebViewRedditClient(host: host), watch),
      catalog: () async =>
          ProviderCatalog.fromJson(jsonDecode(await bundledCatalog()) as Map<String, dynamic>),
    );
    final result = await summarizeWithKeys(api, url, keys);
    final a = result.analysis;
    print('LIVE_OK ${watch.elapsed.inSeconds}s model=${result.meta.model} '
        'comments=${result.meta.commentsAnalyzed}/${result.meta.commentsTotal} '
        'lang=${a.language} sentiment=${a.sentiment.name} title="${result.thread.title}"');
    print('LIVE_SHORT ${a.shortSummary.replaceAll('\n', ' ')}');
  } catch (e) {
    print('LIVE_FAIL $e');
  }
  exit(0);
}

/// Tries each key in turn: a second key covers a used-up quota or a key that
/// Gemini is serving badly.
Future<SummaryResult> summarizeWithKeys(DirectTldrApi api, String url, List<String> keys) async {
  for (var i = 0;; i++) {
    try {
      return await api.summarize(url: url, provider: ProviderId.gemini, apiKey: keys[i]);
    } on ApiError catch (e) {
      // Not the app's fault: another key may get through.
      const keyProblems = {'LLM_QUOTA_EXCEEDED', 'LLM_KEY_INVALID', 'LLM_UNAVAILABLE', 'TIMEOUT'};
      final keyProblem = keyProblems.contains(e.code);
      if (!keyProblem || i == keys.length - 1) rethrow;
      print('LIVE_NOTE key ${i + 1} ${e.code}, trying the next one');
    }
  }
}

/// Prints how long the WebView read took, to tell a slow Reddit from a slow AI.
class _TimedReddit implements RedditClient {
  _TimedReddit(this.inner, this.watch);

  final RedditClient inner;
  final Stopwatch watch;

  @override
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken}) async {
    final thread = await inner.fetch(url, cancelToken: cancelToken);
    print('LIVE_NOTE thread read in ${watch.elapsed.inSeconds}s, ${thread.comments.length} comments');
    return thread;
  }
}
