import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';
part 'quote_dao.dart';
part 'app_open_log_dao.dart';

@DriftDatabase(
  tables: [QuoteEntries, Favorites, SeenQuotes, AppOpenLog],
  daos: [QuoteDao, AppOpenLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createPerformanceIndexes(m);
      await _createAppOpenLogIndex(m);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Schema v2 created `history_fact_entries`; v7 drops the history-fact
      // feature entirely. Installs upgrading from <7 still carry the table, so
      // drop it explicitly — `createAll()` never revisits existing databases.
      if (from < 3) {
        await m.createTable(appOpenLog);
      }
      if (from < 4) {
        await _createPerformanceIndexes(m);
      }
      if (from < 5) {
        await _createAppOpenLogIndex(m);
      }
      if (from < 6) {
        await m.addColumn(quoteEntries, quoteEntries.author);
      }
      if (from < 7) {
        await m.database.customStatement(
          'DROP TABLE IF EXISTS history_fact_entries',
        );
      }
    },
  );

  Future<void> _createPerformanceIndexes(Migrator m) async {
    // Indexes must be created as separate statements, not table constraints.
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorites_quote_id ON favorites(quote_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_seen_quotes_quote_id ON seen_quotes(quote_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_seen_quotes_date_desc ON seen_quotes(seen_at DESC)',
    );
  }

  Future<void> _createAppOpenLogIndex(Migrator m) async {
    await m.database.customStatement(
      'DELETE FROM app_open_log WHERE id NOT IN (SELECT MIN(id) FROM app_open_log GROUP BY opened_at)',
    );
    await m.database.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_app_open_log_opened_at ON app_open_log(opened_at)',
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'marx_app.sqlite');
}
