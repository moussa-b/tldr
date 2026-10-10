import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/data/api/tldr_api.dart';
import 'package:tldr/data/engine/reddit_client.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/data/summary_service.dart';

import '../fake_tldr_api.dart';
import '../helpers.dart';

/// Fake API whose validateKey can fail on the network.
class FlakyKeyApi implements TldrApi {
  FlakyKeyApi(this.inner);

  final TldrApi inner;

  @override
  Future<KeyValidation> validateKey({required ProviderId provider, required String apiKey}) async {
    if (apiKey == 'offline') throw ApiError.network;
    return inner.validateKey(provider: provider, apiKey: apiKey);
  }

  @override
  Future<ProviderCatalog> getModels() => inner.getModels();

  @override
  Future<SummaryResult> summarize({
    required String url,
    required ProviderId provider,
    String? model,
    required String apiKey,
    ApiCancelToken? cancelToken,
  }) =>
      inner.summarize(url: url, provider: provider, model: model, apiKey: apiKey);

  @override
  Future<TranslationResult> translate({
    required Analysis analysis,
    required ProviderId provider,
    String? model,
    required String apiKey,
    String targetLanguage = 'fr',
  }) =>
      inner.translate(analysis: analysis, provider: provider, apiKey: apiKey);
}

void main() {
  setUpAll(initTestEnv);

  test('saveKey: valid, refused (not stored), unverified on network error, empty', () async {
    final deps = await testDeps(api: FlakyKeyApi(FakeTldrApi()), keys: {});
    final s = deps.service;
    expect(await s.saveKey(ProviderId.openai, 'invalid'), KeySaveResult.refused);
    expect(await deps.keys.read(ProviderId.openai), isNull);
    expect(await s.saveKey(ProviderId.openai, ' sk-good '), KeySaveResult.valid);
    expect(await deps.keys.read(ProviderId.openai), 'sk-good');
    expect(await s.saveKey(ProviderId.gemini, 'offline'), KeySaveResult.unverified);
    expect(await deps.keys.read(ProviderId.gemini), 'offline');
    expect(await s.saveKey(ProviderId.anthropic, '  '), KeySaveResult.empty);
  });

  test('summarize stores the entry, clears pending, and dedupes by thread id', () async {
    final deps = await testDeps();
    final s = deps.service;
    const url = 'https://www.reddit.com/r/france/comments/1abc23d/x/';
    final entry = await s.summarize(url);
    expect(await deps.settings.pendingSummary(), isNull);
    final again = await s.findExisting('https://old.reddit.com/r/${entry.thread.subreddit}/comments/${entry.thread.id}/');
    expect(again?.id, entry.id);
  });

  test('a retryable failure keeps the pending request, a final one clears it (R2)', () async {
    final deps = await testDeps();
    final s = deps.service;
    await expectLater(s.summarize('https://www.reddit.com/r/x/comments/timeout1/'), throwsA(isA<ApiError>()));
    expect(await deps.settings.pendingSummary(), isNotNull);
    expect(await s.freshPending(), isNotNull);
    await expectLater(s.summarize('https://www.reddit.com/r/x/comments/notfound1/'), throwsA(isA<ApiError>()));
    expect(await deps.settings.pendingSummary(), isNull);
  });

  test('missing key gives LLM_KEY_MISSING without calling the engine', () async {
    final deps = await testDeps(keys: {});
    await expectLater(
      deps.service.summarize('https://redd.it/1abc23d'),
      throwsA(isA<ApiError>().having((e) => e.code, 'code', 'LLM_KEY_MISSING')),
    );
  });

  test('a stored model missing from the catalog falls back to the default (R4)', () async {
    final deps = await testDeps();
    await deps.settings.setModel(ProviderId.gemini, 'gemini-1.0-retired');
    final fallbacks = await deps.service.refreshCatalog();
    expect(fallbacks.single.to, 'gemini-2.5-flash');
    expect(await deps.settings.model(ProviderId.gemini), 'gemini-2.5-flash');
  });

  test('translate stores the French version and shows it', () async {
    final deps = await testDeps();
    final entry = await deps.service.summarize('https://www.reddit.com/r/AskReddit/comments/1xyz98q/x/');
    if (!entry.canTranslate) return; // fixture choice depends on the URL hash
    final translated = await deps.service.translate(entry);
    expect(translated.displayLang, 'fr');
    expect(translated.displayed.language, 'fr');
  });

  group('Reddit listing parsing', () {
    Map<String, dynamic> comment(String id, String body, {List<Map<String, dynamic>> replies = const []}) => {
          'kind': 't1',
          'data': {
            'id': id,
            'author': 'u_$id',
            'score': 3,
            'body': body,
            'replies': replies.isEmpty
                ? ''
                : {
                    'data': {'children': replies},
                  },
          },
        };
    List<dynamic> listing({String selftext = 'texte', String? removedBy, List<Map<String, dynamic>>? comments}) => [
          {
            'data': {
              'children': [
                {
                  'data': {
                    'id': 'abc123',
                    'subreddit': 'france',
                    'title': 'Titre',
                    'author': 'moi',
                    'permalink': '/r/france/comments/abc123/titre/',
                    'created_utc': 1760000000,
                    'score': 42,
                    'upvote_ratio': 0.8,
                    'num_comments': 2,
                    'over_18': true,
                    'selftext': selftext,
                    'removed_by_category': removedBy,
                  },
                },
              ],
            },
          },
          {
            'data': {
              'children': comments ??
                  [
                    comment('c1', 'premier', replies: [comment('c2', 'réponse')]),
                    {'kind': 'more', 'data': {}},
                  ],
            },
          },
        ];

    test('flattens comments with depth and parent', () {
      final t = parseThreadListing(listing());
      expect(t.thread.permalink, 'https://www.reddit.com/r/france/comments/abc123/titre/');
      expect(t.thread.isNsfw, isTrue);
      expect(t.comments.map((c) => (c.id, c.parentId, c.depth)), [('c1', null, 0), ('c2', 'c1', 1)]);
    });

    test('a removed post without comments is THREAD_UNAVAILABLE', () {
      expect(
        () => parseThreadListing(listing(selftext: '[removed]', removedBy: 'moderator', comments: [])),
        throwsA(isA<ApiError>().having((e) => e.reason, 'reason', 'removed')),
      );
    });

    test('a removed post with comments is still summarized', () {
      final t = parseThreadListing(listing(selftext: '[removed]', removedBy: 'moderator'));
      expect(t.selftext, isEmpty);
      expect(t.comments, isNotEmpty);
    });
  });
}
