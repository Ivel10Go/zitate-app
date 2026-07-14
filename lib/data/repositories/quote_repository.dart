import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../core/utils/quote_scheduler.dart';
import '../../core/utils/german_text_normalizer.dart';
import '../database/app_database.dart';
import '../models/quote.dart';

class QuoteRepository {
  QuoteRepository(this._db);

  final AppDatabase _db;

  Future<int> quoteCount() => _db.quoteDao.countQuotes();

  Future<void> ensureSeeded() async {
    final raw = await rootBundle.loadString('assets/thinkers_quotes.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const FormatException(
        'assets/thinkers_quotes.json must contain a JSON array',
      );
    }

    final parsed = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map<String, dynamic>) {
        throw FormatException('Quote entry at index $index is not an object');
      }

      final rawId = item['id'];
      if (rawId is String && seenIds.contains(rawId.trim())) {
        // Keep the first occurrence and ignore duplicate seed rows.
        continue;
      }

      _validateSeedEntry(item, index: index, seenIds: seenIds);
      parsed.add(item);
    }

    final quotes = parsed
        .map((Map<String, dynamic> item) => Quote.fromJson(item))
        .toList();

    await _db.quoteDao.upsertQuotes(quotes.map(_toCompanion).toList());
    await _db.quoteDao.pruneQuotesNotIn(
      quotes.map((Quote quote) => quote.id).toSet(),
    );
  }

  Stream<List<Quote>> watchAllQuotes() {
    return _db.quoteDao.watchAllQuoteEntries().map(
      (List<QuoteEntry> rows) => rows.map(_fromEntry).toList(),
    );
  }

  Stream<List<Quote>> watchFavorites() {
    return _db.quoteDao.watchFavoriteQuoteEntries().map(
      (List<QuoteEntry> rows) => rows.map(_fromEntry).toList(),
    );
  }

  Stream<Quote?> watchQuoteById(String id) {
    return _db.quoteDao.watchQuoteById(id).map((QuoteEntry? row) {
      if (row == null) {
        return null;
      }
      return _fromEntry(row);
    });
  }

  Future<Quote?> getQuoteById(String id) async {
    final row = await _db.quoteDao.getQuoteById(id);
    if (row == null) {
      return null;
    }
    return _fromEntry(row);
  }

  Future<Quote?> getDailyQuote() async {
    final allIds = await _db.quoteDao.getAllQuoteIds();
    final id = await QuoteScheduler.pickDailyId(allIds);
    if (id == null) {
      return null;
    }

    final row = await _db.quoteDao.getQuoteById(id);
    if (row == null) {
      return null;
    }

    await _db.quoteDao.markSeen(id);
    return _fromEntry(row);
  }

  Future<Quote?> getNextQuote() async {
    final allIds = await _db.quoteDao.getAllQuoteIds();
    final id = await QuoteScheduler.pickNextId(allIds);
    if (id == null) {
      return null;
    }

    final row = await _db.quoteDao.getQuoteById(id);
    if (row == null) {
      return null;
    }

    await _db.quoteDao.markSeen(id);
    return _fromEntry(row);
  }

  Future<void> addFavorite(String quoteId) => _db.quoteDao.addFavorite(quoteId);

  Future<void> removeFavorite(String quoteId) =>
      _db.quoteDao.removeFavorite(quoteId);

  Future<void> clearUserData() => _db.quoteDao.clearUserData();

  Stream<bool> watchIsFavorite(String quoteId) =>
      _db.quoteDao.watchIsFavorite(quoteId);

  QuoteEntriesCompanion _toCompanion(Quote quote) {
    return QuoteEntriesCompanion.insert(
      id: quote.id,
      textDe: quote.textDe,
      textOriginal: quote.textOriginal,
      author: Value<String>(quote.author),
      source: quote.source,
      year: quote.year,
      chapter: quote.chapter,
      categoryCsv: quote.category.join(', '),
      difficulty: quote.difficulty,
      series: quote.series,
      explanationShort: quote.explanationShort,
      explanationLong: quote.explanationLong,
      relatedIdsCsv: quote.relatedIds.join(', '),
      funFact: Value<String?>(quote.funFact),
    );
  }

  Quote _fromEntry(QuoteEntry row) {
    final categories = row.categoryCsv
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    final related = row.relatedIdsCsv
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    return Quote(
      id: row.id,
      textDe: (normalizeGermanDisplayText(row.textDe) ?? '').trim(),
      textOriginal: (normalizeGermanDisplayText(row.textOriginal) ?? '').trim(),
      author: (normalizeGermanDisplayText(row.author) ?? '').trim(),
      source: (normalizeGermanDisplayText(row.source) ?? '').trim(),
      year: row.year,
      chapter: (normalizeGermanDisplayText(row.chapter) ?? '').trim(),
      category: categories
          .map((item) => (normalizeGermanDisplayText(item) ?? '').trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      difficulty: row.difficulty,
      series: (normalizeGermanDisplayText(row.series) ?? '').trim(),
      explanationShort: (normalizeGermanDisplayText(row.explanationShort) ?? '')
          .trim(),
      explanationLong: (normalizeGermanDisplayText(row.explanationLong) ?? '')
          .trim(),
      relatedIds: related
          .map((item) => (normalizeGermanDisplayText(item) ?? '').trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      funFact: normalizeGermanDisplayText(row.funFact),
    );
  }

  void _validateSeedEntry(
    Map<String, dynamic> item, {
    required int index,
    required Set<String> seenIds,
  }) {
    final id = _requiredString(item, 'id', index);
    seenIds.add(id);

    _requiredString(item, 'text_de', index);
    _requiredString(item, 'text_original', index);
    _requiredString(item, 'author', index);
    _requiredString(item, 'source', index);
    _requiredString(item, 'chapter', index);
    _requiredString(item, 'difficulty', index);
    _requiredString(item, 'series', index);
    _requiredString(item, 'explanation_short', index);
    _requiredString(item, 'explanation_long', index);
    _requiredStringList(item, 'category', index);
    _requiredStringList(item, 'related_ids', index, allowEmpty: true);

    final yearValue = item['year'];
    if (yearValue is! num) {
      throw FormatException(
        'Missing or invalid numeric "year" at index $index',
      );
    }

    final year = yearValue.toInt();
    if (year < -3000 || year > 2100) {
      throw FormatException('Implausible year "$year" at index $index');
    }
  }

  String _requiredString(Map<String, dynamic> item, String key, int index) {
    final value = item[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or empty string "$key" at index $index');
    }
    return value;
  }

  List<String> _requiredStringList(
    Map<String, dynamic> item,
    String key,
    int index, {
    bool allowEmpty = false,
  }) {
    final value = item[key];
    final entries = switch (value) {
      final List<dynamic> list => list,
      final String stringValue => [stringValue],
      _ => throw FormatException(
        'Missing or invalid list "$key" at index $index',
      ),
    };

    final casted = entries
        .whereType<String>()
        .map((String entry) => entry.trim())
        .where((String entry) => entry.isNotEmpty)
        .toList();

    if (!allowEmpty && casted.isEmpty) {
      throw FormatException('List "$key" must not be empty at index $index');
    }
    return casted;
  }
}
