part of 'app_database.dart';

@DriftAccessor(tables: [QuoteEntries, Favorites, SeenQuotes])
class QuoteDao extends DatabaseAccessor<AppDatabase> with _$QuoteDaoMixin {
  QuoteDao(super.db);

  Stream<List<QuoteEntry>> watchAllQuoteEntries() {
    return (select(
      quoteEntries,
    )..orderBy([(QuoteEntries t) => OrderingTerm(expression: t.year)])).watch();
  }

  Future<List<String>> getAllQuoteIds() async {
    // Only select id column to avoid loading large text columns unnecessarily
    final query = selectOnly(quoteEntries)..addColumns([quoteEntries.id]);
    final rows = await query.get();
    return rows.map((row) => row.read(quoteEntries.id)!).toList();
  }

  Stream<QuoteEntry?> watchQuoteById(String id) {
    return (select(
      quoteEntries,
    )..where((QuoteEntries t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<QuoteEntry?> getQuoteById(String id) {
    return (select(
      quoteEntries,
    )..where((QuoteEntries t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> countQuotes() async {
    final countExpression = quoteEntries.id.count();
    final query = selectOnly(quoteEntries)..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<void> upsertQuotes(List<QuoteEntriesCompanion> entries) async {
    await batch((Batch b) {
      b.insertAllOnConflictUpdate(quoteEntries, entries);
    });
  }

  /// Deletes every quote that is no longer part of the seed asset, along with
  /// the favorites/seen rows pointing at it. Seeding is upsert-only, so without
  /// this a quote removed from `thinkers_quotes.json` would survive forever on
  /// installs that had already seeded it.
  Future<void> pruneQuotesNotIn(Set<String> keptIds) async {
    await transaction(() async {
      final staleIds = (await getAllQuoteIds())
          .where((String id) => !keptIds.contains(id))
          .toList();
      if (staleIds.isEmpty) {
        return;
      }

      await (delete(
        favorites,
      )..where((Favorites t) => t.quoteId.isIn(staleIds))).go();
      await (delete(
        seenQuotes,
      )..where((SeenQuotes t) => t.quoteId.isIn(staleIds))).go();
      await (delete(
        quoteEntries,
      )..where((QuoteEntries t) => t.id.isIn(staleIds))).go();
    });
  }

  Stream<List<QuoteEntry>> watchFavoriteQuoteEntries() {
    final query = select(favorites).join(<Join>[
      innerJoin(quoteEntries, quoteEntries.id.equalsExp(favorites.quoteId)),
    ]);

    return query.watch().map(
      (List<TypedResult> rows) =>
          rows.map((TypedResult row) => row.readTable(quoteEntries)).toList(),
    );
  }

  Future<void> addFavorite(String quoteId) async {
    await into(
      favorites,
    ).insertOnConflictUpdate(FavoritesCompanion.insert(quoteId: quoteId));
  }

  Future<void> removeFavorite(String quoteId) async {
    await (delete(
      favorites,
    )..where((Favorites t) => t.quoteId.equals(quoteId))).go();
  }

  Stream<bool> watchIsFavorite(String quoteId) {
    return (select(favorites)
          ..where((Favorites t) => t.quoteId.equals(quoteId)))
        .watch()
        .map((List<Favorite> rows) => rows.isNotEmpty);
  }

  Future<void> markSeen(String quoteId) async {
    await into(seenQuotes).insert(SeenQuotesCompanion.insert(quoteId: quoteId));
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(favorites).go();
      await delete(seenQuotes).go();
      await delete(quoteEntries).go();
    });
  }

  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(favorites).go();
      await delete(seenQuotes).go();
    });
  }
}
