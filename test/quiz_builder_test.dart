import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zitate_app/core/utils/quote_attribution.dart';
import 'package:zitate_app/data/models/quiz_session.dart';
import 'package:zitate_app/data/models/quote.dart';
import 'package:zitate_app/domain/services/quiz_builder.dart';

/// The real seed data, so the builder is exercised against the pool it actually
/// ships with rather than a hand-made fixture.
List<Quote> _loadSeedQuotes() {
  final raw = File('assets/thinkers_quotes.json').readAsStringSync();
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((dynamic item) => Quote.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// A throwaway quote whose only interesting field is [difficulty].
Quote _quoteWithDifficulty(String difficulty) {
  return Quote(
    id: 'fixture_$difficulty',
    textDe: 'Text',
    textOriginal: 'Text',
    author: 'Autor',
    source: 'Werk',
    year: 1900,
    chapter: 'Kapitel',
    category: const <String>['Philosophie'],
    difficulty: difficulty,
    series: 'person_autor',
    explanationShort: 'Kurz',
    explanationLong: 'Lang',
    relatedIds: const <String>[],
  );
}

/// Mirrors what PersonalizationService.getWeightedQuotes hands the builder: the
/// same quote repeated once per unit of weight.
List<Quote> _weightExpanded(List<Quote> quotes, {int copies = 10}) {
  return <Quote>[
    for (final Quote quote in quotes)
      for (int i = 0; i < copies; i++) quote,
  ];
}

void main() {
  late List<Quote> seedQuotes;

  setUpAll(() {
    seedQuotes = _loadSeedQuotes();
  });

  test('seed data carries an author for every quote', () {
    // Deliberately a floor, not an exact count: the pool has to be big enough to
    // draw a run from, but pinning the size makes every content change a test
    // failure. `quote_database_integrity_test.dart` guards the data itself.
    expect(seedQuotes.length, greaterThan(kQuizQuestionCount * 4));
    expect(
      seedQuotes.where((Quote q) => q.author.trim().isEmpty),
      isEmpty,
      reason: 'author is what the quiz asks for; it must never be blank',
    );
  });

  test('answer options are authors, never work titles', () {
    final session = QuizBuilder(
      random: Random(7),
    ).build(candidates: seedQuotes, drawPool: _weightExpanded(seedQuotes));

    final authors = seedQuotes.map(quoteAuthorLabel).toSet();
    final workTitles = seedQuotes.map((Quote q) => q.source).toSet()
      ..removeAll(authors);

    for (final QuizQuestion question in session.questions) {
      for (final String option in question.options) {
        expect(
          authors,
          contains(option),
          reason: '"$option" is not one of the known authors',
        );
        expect(
          workTitles,
          isNot(contains(option)),
          reason: '"$option" is a work title, not a person',
        );
      }
      expect(question.correctOption, quoteAuthorLabel(question.quote));
    }
  });

  test('a run never repeats a quote or an option', () {
    // Repeat across seeds: the old bug surfaced in roughly one run in six, so a
    // single sample would not have caught it.
    for (int seed = 0; seed < 100; seed++) {
      final session = QuizBuilder(
        random: Random(seed),
      ).build(candidates: seedQuotes, drawPool: _weightExpanded(seedQuotes));

      final quoteIds = session.questions
          .map((QuizQuestion q) => q.quote.id)
          .toList();
      expect(
        quoteIds.toSet(),
        hasLength(quoteIds.length),
        reason: 'duplicate question in run with seed $seed',
      );

      for (final QuizQuestion question in session.questions) {
        expect(
          question.options.toSet(),
          hasLength(question.options.length),
          reason: 'duplicate option in run with seed $seed',
        );
      }
    }
  });

  test('a full run has ten questions, with the opening ones cut down', () {
    final session = QuizBuilder(
      random: Random(3),
    ).build(candidates: seedQuotes, drawPool: _weightExpanded(seedQuotes));

    expect(session.totalQuestions, kQuizQuestionCount);
    for (final QuizQuestion question in session.questions) {
      final expected = question.difficulty == 'beginner'
          ? kQuizEasyOptionCount
          : kQuizOptionCount;
      expect(question.options, hasLength(expected));
      expect(question.correctIndex, inInclusiveRange(0, expected - 1));
      expect(question.correctOption, quoteAuthorLabel(question.quote));
    }
  });

  test('a run ramps up instead of opening on an advanced question', () {
    // The old builder shuffled the whole run, so seed 0 could — and did — open
    // with three advanced questions in a row.
    for (int seed = 0; seed < 50; seed++) {
      final session = QuizBuilder(
        random: Random(seed),
      ).build(candidates: seedQuotes, drawPool: _weightExpanded(seedQuotes));

      const rank = <String, int>{
        'beginner': 0,
        'intermediate': 1,
        'advanced': 2,
      };
      final ranks = session.questions
          .map((QuizQuestion q) => rank[q.difficulty]!)
          .toList();

      expect(
        ranks,
        orderedEquals(List<int>.from(ranks)..sort()),
        reason: 'run with seed $seed is not ordered easiest-first',
      );
      expect(
        session.questions.first.difficulty,
        'beginner',
        reason: 'run with seed $seed opens on a hard question',
      );
    }
  });

  test('easier questions get a hint and more time than advanced ones', () {
    final session = QuizBuilder(
      random: Random(11),
    ).build(candidates: seedQuotes, drawPool: _weightExpanded(seedQuotes));

    final beginner = session.questions.firstWhere(
      (QuizQuestion q) => q.difficulty == 'beginner',
    );
    final advanced = session.questions.firstWhere(
      (QuizQuestion q) => q.difficulty == 'advanced',
    );

    expect(beginner.hint, isNotNull);
    expect(advanced.hint, isNull, reason: 'advanced questions stay unaided');

    // Every question now beats the flat 15s the whole quiz used to run on.
    for (final QuizQuestion question in session.questions) {
      expect(question.duration.inSeconds, greaterThanOrEqualTo(25));
    }
  });

  test('era labels stay coarse, and handle antiquity', () {
    expect(QuizBuilder.eraLabel(-500), 'Antike');
    expect(QuizBuilder.eraLabel(180), 'Antike');
    expect(QuizBuilder.eraLabel(1250), 'Mittelalter');
    expect(QuizBuilder.eraLabel(1651), 'Frühe Neuzeit');
    expect(QuizBuilder.eraLabel(1867), '19. Jahrhundert');
    expect(QuizBuilder.eraLabel(1949), '20. Jahrhundert');
    expect(QuizBuilder.eraLabel(2015), '21. Jahrhundert');
  });

  test('every seed quote lands in one of the three buckets', () {
    final buckets = seedQuotes.map(QuizBuilder.normalizedDifficulty).toSet();
    expect(buckets, <String>{'beginner', 'intermediate', 'advanced'});
  });

  test('legacy difficulty aliases still resolve to a bucket', () {
    // The rebuilt seed data uses only beginner/intermediate/advanced, so the
    // aliases no longer appear in it — but the mapping stays covered, because
    // stray easy/medium/hard values are what made ~80 quotes undrawable before.
    const aliases = <String, String>{
      'easy': 'beginner',
      'medium': 'intermediate',
      'hard': 'advanced',
      'unbekannt': 'intermediate', // anything unmapped falls back
    };

    for (final MapEntry<String, String> alias in aliases.entries) {
      expect(
        QuizBuilder.normalizedDifficulty(_quoteWithDifficulty(alias.key)),
        alias.value,
        reason: '"${alias.key}" must resolve to a drawable bucket',
      );
    }
  });

  test('a pool too small for four options yields fewer, and terminates', () {
    // The old generator looped forever here instead of shipping three options.
    final tiny = seedQuotes
        .where((Quote q) => quoteAuthorLabel(q) == 'Karl Marx')
        .take(4)
        .toList();
    final withOneOther = <Quote>[
      ...tiny,
      seedQuotes.firstWhere((Quote q) => quoteAuthorLabel(q) == 'Seneca'),
    ];

    final session = QuizBuilder(
      random: Random(1),
    ).build(candidates: withOneOther, drawPool: withOneOther);

    expect(session.questions, isNotEmpty);
    for (final QuizQuestion question in session.questions) {
      // Only two distinct authors exist, so only two options can be offered.
      expect(question.options, hasLength(2));
      expect(question.correctOption, quoteAuthorLabel(question.quote));
    }
  });

  test('a single-author pool cannot make a quiz', () {
    final marxOnly = seedQuotes
        .where((Quote q) => quoteAuthorLabel(q) == 'Karl Marx')
        .toList();

    final session = QuizBuilder(
      random: Random(1),
    ).build(candidates: marxOnly, drawPool: marxOnly);

    expect(session.isEmpty, isTrue);
    // Distinct from "still building": the screen shows an explanation here, not
    // a spinner that never resolves.
    expect(session.status, QuizStatus.unavailable);
  });

  test('a quote with no resolvable author is never drawn as a question', () {
    // The guard and the distractor pool always excluded these; the draw pool did
    // not, so one could become a question whose correct answer was "".
    final blank = Quote(
      id: 'blank_author',
      textDe: 'Ein Satz ohne zurechenbare Urheberschaft.',
      textOriginal: 'Ein Satz ohne zurechenbare Urheberschaft.',
      author: '',
      source: '',
      year: 1900,
      chapter: '',
      category: const <String>['Philosophie'],
      difficulty: 'beginner',
      series: '',
      explanationShort: 'Kurz',
      explanationLong: 'Lang',
      relatedIds: const <String>[],
    );

    final pool = <Quote>[...seedQuotes.take(30), blank];
    // Heavily weighted, so a builder that draws from the unfiltered pool would
    // pick it almost every run rather than occasionally.
    final drawPool = <Quote>[
      ...pool,
      for (int i = 0; i < 200; i++) blank,
    ];

    final session = QuizBuilder(
      random: Random(7),
    ).build(candidates: pool, drawPool: drawPool);

    expect(session.questions, isNotEmpty);
    expect(
      session.questions.where((QuizQuestion q) => q.quote.id == blank.id),
      isEmpty,
      reason: 'a quote with no author cannot be the answer to "who said this?"',
    );
    for (final QuizQuestion question in session.questions) {
      expect(question.options.where((String o) => o.trim().isEmpty), isEmpty);
    }
  });

  test('a run never exceeds the advertised question count', () {
    // The bucket spread and kQuizQuestionCount are two separate constants; if
    // they drift apart the UI reasons about a different number than it renders.
    final session = QuizBuilder(
      random: Random(3),
    ).build(candidates: seedQuotes, drawPool: _weightExpanded(seedQuotes));

    expect(session.questions.length, lessThanOrEqualTo(kQuizQuestionCount));
  });
}
