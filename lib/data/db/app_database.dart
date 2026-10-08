import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite schema (spec « Schéma SQLite »). sqflite replaces drift because
/// drift_dev cannot resolve with Riverpod 3 on Flutter 3.32 (analyzer/test
/// conflict); the schema is unchanged.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const version = 1;

  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), 'tldr.db');
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) => _createV1(db),
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE summaries (
        id                  TEXT PRIMARY KEY,
        thread_id           TEXT NOT NULL UNIQUE,
        source_url          TEXT NOT NULL,
        permalink           TEXT NOT NULL,
        subreddit           TEXT NOT NULL,
        title               TEXT NOT NULL,
        author              TEXT NOT NULL,
        thread_created_at   INTEGER NOT NULL,
        score               INTEGER NOT NULL,
        upvote_ratio        REAL NOT NULL,
        num_comments        INTEGER NOT NULL,
        is_nsfw             INTEGER NOT NULL,
        provider            TEXT NOT NULL,
        model               TEXT NOT NULL,
        language            TEXT NOT NULL,
        analysis_json       TEXT NOT NULL,
        analysis_fr_json    TEXT,
        sentiment           TEXT NOT NULL,
        top_emotion         TEXT NOT NULL,
        display_lang        TEXT NOT NULL DEFAULT 'orig',
        comments_analyzed   INTEGER NOT NULL,
        comments_total      INTEGER NOT NULL,
        created_at          INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX summaries_created_at_idx ON summaries (created_at DESC)');
    await db.execute('CREATE INDEX summaries_source_url_idx ON summaries (source_url)');
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');
  }

  Future<void> close() => db.close();
}
