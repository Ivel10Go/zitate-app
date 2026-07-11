import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../core/utils/german_text_normalizer.dart';
import '../database/app_database.dart';
import '../models/history_fact.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  Future<int> factCount() => _db.historyFactDao.countHistoryFacts();

  Future<void> ensureSeeded() async {
    final raw = await rootBundle.loadString('assets/history_facts.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final facts = decoded
        .map(
          (dynamic item) => HistoryFact.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    await _db.historyFactDao.upsertHistoryFacts(
      facts.map(_toCompanion).toList(),
    );
  }

  Stream<List<HistoryFact>> watchAllHistoryFacts() {
    return _db.historyFactDao.watchAllHistoryFactEntries().map(
      (List<HistoryFactEntry> rows) => rows.map(_fromEntry).toList(),
    );
  }

  Stream<HistoryFact?> watchHistoryFactById(String id) {
    return _db.historyFactDao.watchHistoryFactById(id).map((
      HistoryFactEntry? row,
    ) {
      if (row == null) {
        return null;
      }
      return _fromEntry(row);
    });
  }

  Future<HistoryFact?> getHistoryFactById(String id) async {
    final row = await _db.historyFactDao.getHistoryFactById(id);
    if (row == null) {
      return null;
    }
    return _fromEntry(row);
  }

  Future<HistoryFact?> getDailyHistoryFact() async {
    final allIds = await _db.historyFactDao.getAllHistoryFactIds();
    if (allIds.isEmpty) {
      return null;
    }

    // Deterministic selection based on day of year
    final now = DateTime.now();
    final dayOfYear = int.parse(
      now.difference(DateTime(now.year)).inDays.toString(),
    );
    final index = dayOfYear % allIds.length;
    final id = allIds[index];

    final row = await _db.historyFactDao.getHistoryFactById(id);
    if (row == null) {
      return null;
    }

    return _fromEntry(row);
  }

  HistoryFactEntriesCompanion _toCompanion(HistoryFact fact) {
    return HistoryFactEntriesCompanion.insert(
      id: fact.id,
      headline: fact.headline,
      body: fact.body,
      dateDisplay: fact.dateDisplay,
      dateIso: fact.dateIso,
      dayOfYear: fact.dayOfYear,
      era: fact.era,
      region: fact.region,
      categoryCsv: fact.category.join(', '),
      difficulty: fact.difficulty,
      person: Value<String?>(fact.person),
      personRole: Value<String?>(fact.personRole),
      connectionToMarx: fact.connectionToMarx,
      relatedQuoteIdsCsv: fact.relatedQuoteIds.join(', '),
      funFact: Value<String?>(fact.funFact),
      source: Value<String?>(fact.source),
      todayInHistory: Value<bool>(fact.todayInHistory),
    );
  }

  HistoryFact _fromEntry(HistoryFactEntry row) {
    final categories = row.categoryCsv
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    final relatedIds = row.relatedQuoteIdsCsv
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    return HistoryFact(
      id: row.id,
      headline: (normalizeGermanDisplayText(row.headline) ?? '').trim(),
      body: (normalizeGermanDisplayText(row.body) ?? '').trim(),
      dateDisplay: (normalizeGermanDisplayText(row.dateDisplay) ?? '').trim(),
      dateIso: row.dateIso,
      dayOfYear: row.dayOfYear,
      era: (normalizeGermanDisplayText(row.era) ?? '').trim(),
      region: (normalizeGermanDisplayText(row.region) ?? '').trim(),
      category: categories
          .map((item) => (normalizeGermanDisplayText(item) ?? '').trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      difficulty: row.difficulty,
      person: normalizeGermanDisplayText(row.person),
      personRole: normalizeGermanDisplayText(row.personRole),
      connectionToMarx: (normalizeGermanDisplayText(row.connectionToMarx) ?? '')
          .trim(),
      relatedQuoteIds: relatedIds
          .map((item) => (normalizeGermanDisplayText(item) ?? '').trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      funFact: normalizeGermanDisplayText(row.funFact),
      source: normalizeGermanDisplayText(row.source),
      todayInHistory: row.todayInHistory,
    );
  }
}
