@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/data/engine/direct_tldr_api.dart';
import 'package:tldr/data/engine/reddit_client.dart';
import 'package:tldr/data/models/models.dart';

/// A real Reddit thread (test/fixtures/reddit_thread_founder.json, read
/// through the WebView) summarized by the real Gemini API, with the keys in
/// gemini.keys (git-ignored, one per line). Skipped when the file is missing.
/// The thread read itself is checked on devices by tool/live_summary.sh.
class _FixtureReddit implements RedditClient {
  @override
  Future<RedditThread> fetch(String url, {CancelToken? cancelToken}) async => parseThreadListing(
      jsonDecode(File('test/fixtures/reddit_thread_founder.json').readAsStringSync()) as List);
}

void main() {
  final keysFile = File('gemini.keys');
  final keys = keysFile.existsSync()
      ? keysFile.readAsLinesSync().map((k) => k.trim()).where((k) => k.isNotEmpty).toList()
      : <String>[];

  test('a real thread gets a real Gemini summary', () async {
    final api = DirectTldrApi(
      reddit: _FixtureReddit(),
      catalog: () async => ProviderCatalog.fromJson(
          jsonDecode(File('assets/catalog.json').readAsStringSync()) as Map<String, dynamic>),
    );
    const url = 'https://www.reddit.com/r/founder/comments/1x1wi5n/someone_copied_my_saas/';

    SummaryResult? result;
    for (final key in keys) {
      try {
        result = await api.summarize(url: url, provider: ProviderId.gemini, apiKey: key);
        break;
      } on ApiError catch (e) {
        // A second key covers a used-up quota or a key Gemini serves badly.
        const keyProblems = {'LLM_QUOTA_EXCEEDED', 'LLM_UNAVAILABLE', 'TIMEOUT'};
        if (!keyProblems.contains(e.code)) rethrow;
        if (key == keys.last) {
          // Every key used up its free quota: says nothing about the app.
          if (e.code == 'LLM_QUOTA_EXCEEDED') return markTestSkipped('Gemini quota used up on every key');
          rethrow;
        }
      }
    }

    final r = result!;
    final a = r.analysis;
    expect(r.thread.id, '1x1wi5n');
    expect(r.thread.title, 'Someone copied my SaaS');
    expect(r.meta.commentsAnalyzed, greaterThan(10));
    expect(a.language, isNotEmpty);
    expect(a.shortSummary.length, greaterThan(40));
    expect(a.detailedSummary.length, greaterThan(a.shortSummary.length));
    expect(a.aiTake, isNotEmpty);
    expect(a.emotions.length, inInclusiveRange(1, 4));
    // On topic: the summary talks about the copied product.
    expect('${a.shortSummary} ${a.detailedSummary}'.toLowerCase(),
        anyOf(contains('saas'), contains('cop'), contains('clone')));
    printOnFailure('${r.meta.model}: ${a.shortSummary}');
  },
      timeout: const Timeout(Duration(minutes: 4)),
      skip: keys.isEmpty ? 'gemini.keys missing' : false);
}
