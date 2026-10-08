import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/db/summaries_dao.dart';
import 'package:tldr/data/models/models.dart';

import '../helpers.dart';

Future<SummaryResult> fixture(String name) async =>
    SummaryResult.fromJson(jsonDecode(await fileFixture(name)) as Map<String, dynamic>);

void main() {
  setUpAll(initTestEnv);

  late SummariesDao dao;
  var now = DateTime(2026, 10, 9, 10);

  setUp(() async {
    final db = await openTestDb();
    dao = SummariesDao(db.db, clock: () => now);
  });

  test('upsert keeps one row per thread and clears the translation (R3)', () async {
    final result = await fixture('summary_en_long.json');
    final first = await dao.upsert(result, sourceUrl: 'https://redd.it/1xyz98q');
    final fr = TranslationResult.fromJson(
        jsonDecode(await fileFixture('translation_fr.json')) as Map<String, dynamic>);
    await dao.saveTranslation(first.id, fr.analysis);
    expect((await dao.getById(first.id))!.displayLang, 'fr');

    now = now.add(const Duration(hours: 1));
    final second = await dao.upsert(result, sourceUrl: 'https://redd.it/1xyz98q');
    expect(second.id, first.id);
    final stored = (await dao.getById(first.id))!;
    expect(stored.analysisFr, isNull);
    expect(stored.displayLang, 'orig');
    expect(await dao.page(), hasLength(1));
  });

  test('history is newest first and never loads analysis JSON (T9)', () async {
    now = DateTime(2026, 10, 9, 8);
    await dao.upsert(await fixture('summary_fr.json'), sourceUrl: 'a');
    now = DateTime(2026, 10, 9, 9);
    await dao.upsert(await fixture('summary_link.json'), sourceUrl: 'b');
    final page = await dao.page();
    expect(page.map((i) => i.subreddit), ['technology', 'france']);
    expect(page.first.sentiment, Sentiment.negative);
    expect(page.first.topEmotion, 'anger');
  });

  test('delete returns the entry and restore puts it back', () async {
    final entry = await dao.upsert(await fixture('summary_fr.json'), sourceUrl: 'a');
    final deleted = await dao.delete(entry.id);
    expect(await dao.page(), isEmpty);
    await dao.restore(deleted!);
    expect((await dao.getById(entry.id))!.thread.title, entry.thread.title);
  });

  test('lookup by thread id and by source url', () async {
    await dao.upsert(await fixture('summary_fr.json'), sourceUrl: 'https://www.reddit.com/r/france/s/X');
    expect(await dao.findByThreadId('1abc23d'), isNotNull);
    expect(await dao.findBySourceUrl('https://www.reddit.com/r/france/s/X'), isNotNull);
    expect(await dao.findBySourceUrl('https://www.reddit.com/r/france/s/Y'), isNull);
  });
}
