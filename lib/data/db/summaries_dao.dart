import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// Light row for the history list: never reads analysis_json (eng review T9).
class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.title,
    required this.subreddit,
    required this.provider,
    required this.createdAt,
    required this.isNsfw,
    required this.sentiment,
    required this.topEmotion,
  });

  final String id;
  final String title;
  final String subreddit;
  final ProviderId provider;
  final DateTime createdAt;
  final bool isNsfw;
  final Sentiment sentiment;
  final String topEmotion;
}

/// A full history entry.
class SummaryEntry {
  const SummaryEntry({
    required this.id,
    required this.sourceUrl,
    required this.thread,
    required this.provider,
    required this.model,
    required this.analysis,
    required this.analysisFr,
    required this.displayLang,
    required this.commentsAnalyzed,
    required this.commentsTotal,
    required this.createdAt,
  });

  final String id;
  final String sourceUrl;
  final Thread thread;
  final ProviderId provider;
  final String model;
  final Analysis analysis;
  final Analysis? analysisFr;

  /// `orig` or `fr` (spec D-9).
  final String displayLang;
  final int commentsAnalyzed;
  final int commentsTotal;
  final DateTime createdAt;

  Analysis get displayed =>
      displayLang == 'fr' && analysisFr != null ? analysisFr! : analysis;

  bool get canTranslate => analysis.language != 'fr';

  Map<String, Object?> toRow() => {
        'id': id,
        'thread_id': thread.id,
        'source_url': sourceUrl,
        'permalink': thread.permalink,
        'subreddit': thread.subreddit,
        'title': thread.title,
        'author': thread.author,
        'thread_created_at': thread.createdAt.millisecondsSinceEpoch,
        'score': thread.score,
        'upvote_ratio': thread.upvoteRatio,
        'num_comments': thread.numComments,
        'is_nsfw': thread.isNsfw ? 1 : 0,
        'provider': provider.name,
        'model': model,
        'language': analysis.language,
        'analysis_json': jsonEncode(analysis.toJson()),
        'analysis_fr_json':
            analysisFr == null ? null : jsonEncode(analysisFr!.toJson()),
        'sentiment': analysis.sentiment.name,
        'top_emotion': analysis.emotions.first,
        'display_lang': displayLang,
        'comments_analyzed': commentsAnalyzed,
        'comments_total': commentsTotal,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory SummaryEntry.fromRow(Map<String, Object?> row) {
    final frJson = row['analysis_fr_json'] as String?;
    return SummaryEntry(
      id: row['id']! as String,
      sourceUrl: row['source_url']! as String,
      thread: Thread(
        id: row['thread_id']! as String,
        subreddit: row['subreddit']! as String,
        title: row['title']! as String,
        author: row['author']! as String,
        permalink: row['permalink']! as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['thread_created_at']! as int),
        score: row['score']! as int,
        upvoteRatio: (row['upvote_ratio']! as num).toDouble(),
        numComments: row['num_comments']! as int,
        isNsfw: row['is_nsfw'] == 1,
        selftextExcerpt: null,
      ),
      provider: ProviderId.fromJson(row['provider']! as String),
      model: row['model']! as String,
      analysis: Analysis.fromJson(
          jsonDecode(row['analysis_json']! as String) as Map<String, dynamic>),
      analysisFr: frJson == null
          ? null
          : Analysis.fromJson(jsonDecode(frJson) as Map<String, dynamic>),
      displayLang: row['display_lang']! as String,
      commentsAnalyzed: row['comments_analyzed']! as int,
      commentsTotal: row['comments_total']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    );
  }
}

class SummariesDao {
  SummariesDao(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Database _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();
  static const pageSize = 50;

  /// One row per thread: an existing row is replaced in place (same id), the
  /// French translation is cleared and the display language reset
  /// (eng review R3, spec D-9).
  Future<SummaryEntry> upsert(SummaryResult result, {required String sourceUrl}) async {
    return _db.transaction((txn) async {
      final existing = await txn.query('summaries',
          columns: ['id'], where: 'thread_id = ?', whereArgs: [result.thread.id]);
      final entry = SummaryEntry(
        id: existing.isEmpty ? _uuid.v4() : existing.first['id']! as String,
        sourceUrl: sourceUrl,
        thread: result.thread,
        provider: result.meta.provider,
        model: result.meta.model,
        analysis: result.analysis,
        analysisFr: null,
        displayLang: 'orig',
        commentsAnalyzed: result.meta.commentsAnalyzed,
        commentsTotal: result.meta.commentsTotal,
        createdAt: _clock(),
      );
      await txn.insert('summaries', entry.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return entry;
    });
  }

  Future<SummaryEntry?> getById(String id) async {
    final rows = await _db.query('summaries', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : SummaryEntry.fromRow(rows.first);
  }

  Future<SummaryEntry?> findByThreadId(String threadId) async {
    final rows =
        await _db.query('summaries', where: 'thread_id = ?', whereArgs: [threadId]);
    return rows.isEmpty ? null : SummaryEntry.fromRow(rows.first);
  }

  Future<SummaryEntry?> findBySourceUrl(String url) async {
    final rows = await _db.query('summaries',
        where: 'source_url = ?', whereArgs: [url.trim()], limit: 1);
    return rows.isEmpty ? null : SummaryEntry.fromRow(rows.first);
  }

  Future<List<HistoryItem>> page({int offset = 0, int limit = pageSize}) async {
    final rows = await _db.query(
      'summaries',
      columns: [
        'id',
        'title',
        'subreddit',
        'provider',
        'created_at',
        'is_nsfw',
        'sentiment',
        'top_emotion',
      ],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows
        .map((r) => HistoryItem(
              id: r['id']! as String,
              title: r['title']! as String,
              subreddit: r['subreddit']! as String,
              provider: ProviderId.fromJson(r['provider']! as String),
              createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
              isNsfw: r['is_nsfw'] == 1,
              sentiment: Sentiment.fromJson(r['sentiment']! as String),
              topEmotion: r['top_emotion']! as String,
            ))
        .toList();
  }

  Future<void> saveTranslation(String id, Analysis fr) => _db.update(
        'summaries',
        {'analysis_fr_json': jsonEncode(fr.toJson()), 'display_lang': 'fr'},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> setDisplayLang(String id, String lang) => _db.update(
      'summaries', {'display_lang': lang},
      where: 'id = ?', whereArgs: [id]);

  /// Returns the deleted entry so the UI can offer « Annuler » (spec).
  Future<SummaryEntry?> delete(String id) async {
    final entry = await getById(id);
    if (entry != null) {
      await _db.delete('summaries', where: 'id = ?', whereArgs: [id]);
    }
    return entry;
  }

  Future<void> restore(SummaryEntry entry) => _db.insert('summaries', entry.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> clear() => _db.delete('summaries');
}
