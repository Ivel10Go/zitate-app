import 'dart:math';

import '../../core/utils/quote_attribution.dart';
import '../../data/models/quiz_session.dart';
import '../../data/models/quote.dart';

/// Turns a pool of quotes into a quiz run.
///
/// Kept free of Riverpod and the database so the selection rules — distinct
/// questions, author-based options, difficulty spread — can be exercised
/// directly against the seed data.
class QuizBuilder {
  QuizBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// The seed data uses two vocabularies for the same three levels
  /// (easy/medium/hard alongside beginner/intermediate/advanced). Without this
  /// mapping ~80 quotes fall out of every difficulty bucket.
  static const Map<String, String> _difficultyAliases = <String, String>{
    'easy': 'beginner',
    'beginner': 'beginner',
    'medium': 'intermediate',
    'intermediate': 'intermediate',
    'hard': 'advanced',
    'advanced': 'advanced',
  };

  /// How many questions to draw per difficulty, easiest first.
  ///
  /// Weighted towards the easier buckets on purpose: the seed pool holds ~200
  /// authors across ~300 quotes, so most authors appear exactly once and an
  /// all-advanced run is closer to a memory test than a quiz.
  static const Map<String, int> _questionsPerDifficulty = <String, int>{
    'beginner': 4,
    'intermediate': 4,
    'advanced': 2,
  };

  /// Base clock per bucket. Reading a long quote plus four names does not fit in
  /// the 15s every question used to get.
  static const Map<String, Duration> _baseDuration = <String, Duration>{
    'beginner': Duration(seconds: 35),
    'intermediate': Duration(seconds: 30),
    'advanced': Duration(seconds: 25),
  };

  /// Extra reading time granted per word beyond [_freeWordAllowance], so a
  /// three-line quote is not silently harder than a one-liner.
  static const int _freeWordAllowance = 20;
  static const Duration _maxReadingBonus = Duration(seconds: 20);

  /// [candidates] are the distinct quotes available. [drawPool] is the
  /// weight-expanded variant of the same quotes produced by
  /// `PersonalizationService.getWeightedQuotes`, in which a quote appears once
  /// per unit of weight — so every read of it must de-duplicate.
  ///
  /// Returns a [QuizStatus.unavailable] session when the pool cannot support a
  /// quiz, i.e. when it holds fewer than two distinct authors and no question
  /// would be answerable. That status is distinct from [QuizStatus.loading] so
  /// the screen can explain the situation instead of spinning forever.
  QuizSession build({
    required List<Quote> candidates,
    required List<Quote> drawPool,
  }) {
    final answerable = candidates
        .where((Quote q) => quoteAuthorLabelOrEmpty(q).trim().isNotEmpty)
        .toList();
    final authors = answerable.map(quoteAuthorLabelOrEmpty).toSet();

    if (answerable.isEmpty || authors.length < 2) {
      return QuizSession.unavailable();
    }

    // The draw pool has to be held to the same standard as [answerable]: a quote
    // with no resolvable author was already excluded from the guard above and
    // from the distractor pool, but drawing one anyway produced a question whose
    // correct answer was the empty string — a blank button that happened to be
    // right, with a valid correctIndex, so nothing failed loudly.
    final answerableIds = answerable.map((Quote q) => q.id).toSet();
    final answerableDrawPool = drawPool
        .where((Quote q) => answerableIds.contains(q.id))
        .toList();

    final usedQuoteIds = <String>{};
    // Paired with the bucket it was drawn for, not the bucket it declares: a
    // top-up quote must be asked at the difficulty of the slot it fills.
    final selected = <_Draw>[];

    for (final MapEntry<String, int> bucket
        in _questionsPerDifficulty.entries) {
      final byDifficulty = answerableDrawPool
          .where((Quote q) => normalizedDifficulty(q) == bucket.key)
          .toList();
      selected.addAll(
        _drawDistinct(byDifficulty, bucket.value, usedQuoteIds)
            .map((Quote q) => _Draw(q, bucket.key)),
      );
    }

    // Buckets can come up short on a small or heavily filtered pool; top up from
    // everything left over so a run still gets a full set of questions.
    if (selected.length < kQuizQuestionCount) {
      selected.addAll(
        _drawDistinct(
          answerableDrawPool,
          kQuizQuestionCount - selected.length,
          usedQuoteIds,
        ).map((Quote q) => _Draw(q, normalizedDifficulty(q))),
      );
    }

    // The buckets currently sum to exactly kQuizQuestionCount, so this trims
    // nothing today. It is here so that retuning the spread — or lowering the
    // question count — cannot silently ship runs longer than the rest of the UI
    // (start screen, progress bar, result screen) reasons about.
    if (selected.length > kQuizQuestionCount) {
      selected.removeRange(kQuizQuestionCount, selected.length);
    }

    // Deliberately not shuffled: the run ramps up, so the first questions are
    // winnable and the hard ones arrive once the user is warmed up. Only the
    // order *within* a difficulty is randomised, by the draw itself.
    selected.sort((_Draw a, _Draw b) {
      return _difficultyRank(a.difficulty).compareTo(
        _difficultyRank(b.difficulty),
      );
    });

    return QuizSession(
      questions: selected
          .map((_Draw draw) => _buildQuestion(draw, answerable))
          .toList(),
      currentIndex: 0,
      isComplete: false,
    );
  }

  static int _difficultyRank(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 0;
      case 'advanced':
        return 2;
      default:
        return 1;
    }
  }

  /// Draws up to [count] quotes from a weight-expanded [pool], skipping any
  /// quote already taken. Shuffling the expanded pool preserves the
  /// personalization weighting, while [usedIds] guarantees distinct questions.
  List<Quote> _drawDistinct(List<Quote> pool, int count, Set<String> usedIds) {
    if (count <= 0 || pool.isEmpty) {
      return <Quote>[];
    }

    final shuffled = List<Quote>.from(pool)..shuffle(_random);
    final drawn = <Quote>[];

    for (final Quote quote in shuffled) {
      if (drawn.length >= count) {
        break;
      }
      if (usedIds.add(quote.id)) {
        drawn.add(quote);
      }
    }

    return drawn;
  }

  QuizQuestion _buildQuestion(_Draw draw, List<Quote> candidates) {
    final Quote quote = draw.quote;
    final correct = quoteAuthorLabelOrEmpty(quote);
    final optionCount = draw.difficulty == 'beginner'
        ? kQuizEasyOptionCount
        : kQuizOptionCount;

    final options = <String>[
      correct,
      ..._pickDistractors(quote, candidates, draw.difficulty, optionCount - 1),
    ]..shuffle(_random);

    return QuizQuestion(
      quote: quote,
      options: options,
      correctIndex: options.indexOf(correct),
      difficulty: draw.difficulty,
      duration: _durationFor(quote, draw.difficulty),
      // Advanced questions are the ones meant to be earned, so no nudge there.
      hint: draw.difficulty == 'advanced' ? null : eraLabel(quote.year),
    );
  }

  /// Base time for the bucket plus an allowance for quotes that take a while to
  /// read, capped so a long passage cannot stall the run.
  Duration _durationFor(Quote quote, String difficulty) {
    final base = _baseDuration[difficulty] ?? kQuizQuestionDuration;
    final words = quote.textDe.trim().split(RegExp(r'\s+')).length;
    final extraWords = max(0, words - _freeWordAllowance);
    final bonusSeconds = min(
      _maxReadingBonus.inSeconds,
      (extraWords / 3).ceil(),
    );
    return base + Duration(seconds: bonusSeconds);
  }

  /// Picks distinct wrong authors, at a distance that follows [difficulty].
  ///
  /// Was previously always "as confusable as possible" — contemporaries and
  /// same-theme authors first — which made every one of the ten questions a
  /// specialist question. Now only the advanced ones work that way: beginner
  /// questions get authors from another era and another subject, so the quote's
  /// own tone and vocabulary are enough to rule them out.
  List<String> _pickDistractors(
    Quote quote,
    List<Quote> candidates,
    String difficulty,
    int wanted,
  ) {
    final correct = quoteAuthorLabelOrEmpty(quote);
    final themes = quote.category.map((String c) => c.toLowerCase()).toSet();

    final related = <String>{};
    final others = <String>{};

    for (final Quote other in candidates) {
      final author = quoteAuthorLabelOrEmpty(other);
      if (author == correct) {
        continue;
      }

      final sharesTheme = other.category.any(
        (String c) => themes.contains(c.toLowerCase()),
      );
      final isContemporary = (other.year - quote.year).abs() <= 100;

      if (sharesTheme || isContemporary) {
        related.add(author);
      } else {
        others.add(author);
      }
    }

    // An author can qualify as related through one quote and not through
    // another; keep each name in a single tier.
    others.removeAll(related);

    // Which tier to exhaust first. Intermediate takes one near miss and fills
    // the rest from far away, so it reads as a step up without being a cliff.
    final List<Set<String>> tiers;
    switch (difficulty) {
      case 'beginner':
        tiers = <Set<String>>[others, related];
      case 'advanced':
        tiers = <Set<String>>[related, others];
      default:
        final nearMiss = related.toList()..shuffle(_random);
        tiers = <Set<String>>[
          nearMiss.take(1).toSet(),
          others,
          related,
        ];
    }

    final distractors = <String>[];
    for (final Set<String> tier in tiers) {
      if (distractors.length >= wanted) {
        break;
      }
      final tierList = tier.toList()..shuffle(_random);
      distractors.addAll(
        tierList
            .where((String a) => !distractors.contains(a))
            .take(wanted - distractors.length),
      );
    }

    // Deliberately no padding loop: if the pool holds fewer other authors than
    // asked for, the question simply shows fewer options rather than spinning.
    return distractors;
  }

  /// Coarse era label used as the hint on non-advanced questions. Coarse on
  /// purpose — it should narrow the field, not hand over the answer.
  static String eraLabel(int year) {
    if (year <= 0) {
      return 'Antike';
    }
    if (year < 500) {
      return 'Antike';
    }
    if (year < 1500) {
      return 'Mittelalter';
    }
    if (year < 1800) {
      return 'Frühe Neuzeit';
    }
    if (year < 1900) {
      return '19. Jahrhundert';
    }
    if (year < 2000) {
      return '20. Jahrhundert';
    }
    return '21. Jahrhundert';
  }

  static String normalizedDifficulty(Quote quote) {
    final raw = quote.difficulty.trim().toLowerCase();
    return _difficultyAliases[raw] ?? 'intermediate';
  }
}

/// A drawn quote together with the slot it was drawn for.
class _Draw {
  const _Draw(this.quote, this.difficulty);

  final Quote quote;
  final String difficulty;
}
