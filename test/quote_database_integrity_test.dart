import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zitate_app/data/models/quote.dart';

/// Guards `assets/thinkers_quotes.json` against the three defects that forced a
/// full rebuild of the quote database in July 2026:
///
/// 1. fabricated quotes — LLM-written summary sentences attributed to real
///    people as verbatim quotations, including padded work-series and one fake
///    Marx sentence duplicated across nine entries;
/// 2. template explanations — a single paragraph with the author's name swapped
///    in, identical for Einstein, Gramsci and Schopenhauer, plus explanations
///    that described the recommendation algorithm instead of the quote;
/// 3. corrupted spelling — an offline `ue`/`oe`/`ae` normalizer that rewrote
///    non-German words ("Virtue" -> "Virtü", "Goethe" -> "Göthe").
///
/// Defects 2 and 3 leave textual fingerprints and are asserted against directly.
/// Defect 1 cannot be detected mechanically — a fabricated quote is
/// indistinguishable from a real one by any rule — so what is enforced here is
/// the structural sloppiness that came with it: duplicate texts and ids.
/// Authenticity itself is a review obligation, documented in CLAUDE.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> entries;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/thinkers_quotes.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    entries = decoded.cast<Map<String, dynamic>>();
  });

  test('asset is a non-empty array that parses into Quote objects', () {
    expect(entries, isNotEmpty);
    for (final entry in entries) {
      expect(
        () => Quote.fromJson(entry),
        returnsNormally,
        reason: 'Quote.fromJson threw for ${entry['id']}',
      );
    }
  });

  test('every quote carries the fields the seed validator requires', () {
    const requiredStrings = <String>[
      'id',
      'text_de',
      'text_original',
      'author',
      'source',
      'chapter',
      'difficulty',
      'series',
      'explanation_short',
      'explanation_long',
    ];

    for (final entry in entries) {
      for (final key in requiredStrings) {
        final value = entry[key];
        expect(
          value is String && value.trim().isNotEmpty,
          isTrue,
          reason: 'Missing or empty "$key" in ${entry['id']}',
        );
      }

      expect(
        entry['category'],
        isA<List<dynamic>>().having((l) => l.length, 'categories', greaterThan(0)),
        reason: 'Empty category list in ${entry['id']}',
      );
      expect(entry['related_ids'], isA<List<dynamic>>());

      final year = entry['year'];
      expect(year, isA<num>(), reason: 'Non-numeric year in ${entry['id']}');
      expect(
        (year as num).toInt(),
        inInclusiveRange(-3000, 2100),
        reason: 'Implausible year in ${entry['id']}',
      );
    }
  });

  test('ids and quote texts are unique', () {
    final ids = <String>{};
    final texts = <String>{};

    for (final entry in entries) {
      final id = entry['id'] as String;
      final text = (entry['text_de'] as String).trim();

      expect(ids.add(id), isTrue, reason: 'Duplicate id: $id');
      expect(
        texts.add(text),
        isTrue,
        reason: 'Duplicate quote text on $id — the old database shipped one '
            'fabricated Marx sentence nine times, once per work.',
      );
    }
  });

  test('related_ids all resolve to quotes that exist', () {
    final ids = entries.map((e) => e['id'] as String).toSet();

    for (final entry in entries) {
      for (final related in entry['related_ids'] as List<dynamic>) {
        expect(
          ids.contains(related),
          isTrue,
          reason: '${entry['id']} points at missing quote "$related"',
        );
      }
    }
  });

  test('no explanation is generated from the old filler template', () {
    // Exact phrases from the template that produced 140 content-free
    // explanations, plus the wording of the ones that described the
    // recommendation algorithm rather than the quote.
    const bannedPhrases = <String>[
      'verdichtet einen komplexen Sachverhalt',
      'Zusammenspiel von Struktur und Prozess',
      'brachte bedeutende Gedanken ein',
      'konzeptualisiert hier einen Aspekt von',
      'verbessert die neutrale Auswahl',
      'stärkt neutrale und mitte-nahe Empfehlungen',
      'ausserhalb des Marx-Pools',
      'schliesst eine klare Lücke',
    ];

    for (final entry in entries) {
      final explanations =
          '${entry['explanation_short']} ${entry['explanation_long']}';
      for (final phrase in bannedPhrases) {
        expect(
          explanations.contains(phrase),
          isFalse,
          reason: '${entry['id']} contains template phrase "$phrase"',
        );
      }
    }
  });

  test('explanations are substantial, not one-liners', () {
    for (final entry in entries) {
      expect(
        (entry['explanation_short'] as String).trim().length,
        greaterThanOrEqualTo(40),
        reason: 'explanation_short too thin in ${entry['id']}',
      );
      expect(
        (entry['explanation_long'] as String).trim().length,
        greaterThanOrEqualTo(250),
        reason: 'explanation_long too thin in ${entry['id']}',
      );
    }
  });

  test('the ue/oe/ae normalizer has not corrupted any words again', () {
    // Casualties of tools/normalize_umlauts.py, which rewrote these sequences
    // inside non-German words as well.
    const corruptions = <String>[
      'Virtü',
      'Pöms',
      'Eclogüs',
      'Äneid',
      'Göthe',
      'Bonhöffer',
      'Dostövsky',
      'Güvara',
      'individülle',
      'intellektülle',
      'Aktüller',
      'Zitatqülle',
      'tocqüville',
    ];

    for (final entry in entries) {
      final haystack = <String>[
        entry['author'] as String,
        entry['source'] as String,
        entry['chapter'] as String,
        entry['text_de'] as String,
        entry['explanation_short'] as String,
        entry['explanation_long'] as String,
      ].join(' ');

      for (final corruption in corruptions) {
        expect(
          haystack.contains(corruption),
          isFalse,
          reason: '${entry['id']} contains corrupted spelling "$corruption" — '
              'did tools/normalize_umlauts.py run over the asset again?',
        );
      }
    }
  });
}
