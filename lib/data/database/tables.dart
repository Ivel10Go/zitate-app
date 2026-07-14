import 'package:drift/drift.dart';

class QuoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get textDe => text()();
  TextColumn get textOriginal => text()();

  /// The person a quote is attributed to. Distinct from [source], which is the
  /// work it appears in ("Das Kapital Band 1", "Menon"). Defaults to empty so
  /// rows written before schema v6 stay readable until the seed backfills them;
  /// use `quoteAuthorLabel()` rather than reading this directly.
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get source => text()();
  IntColumn get year => integer()();
  TextColumn get chapter => text()();
  TextColumn get categoryCsv => text()();
  TextColumn get difficulty => text()();
  TextColumn get series => text()();
  TextColumn get explanationShort => text()();
  TextColumn get explanationLong => text()();
  TextColumn get relatedIdsCsv => text()();
  TextColumn get funFact => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get quoteId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SeenQuotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get quoteId => text()();
  DateTimeColumn get seenAt => dateTime().withDefault(currentDateAndTime)();
}

class AppOpenLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get openedAt => dateTime()();

  @override
  List<String> get customConstraints => <String>['UNIQUE(opened_at)'];
}
