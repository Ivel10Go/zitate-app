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
  static const Map<String, int> _questionsPerDifficulty = <String, int>{
    'beginner': 3,
    'intermediate': 4,
    'advanced': 3,
  };

  /// [candidates] are the distinct quotes available. [drawPool] is the
  /// weight-expanded variant of the same quotes produced by
  /// `PersonalizationService.getWeightedQuotes`, in which a quote appears once
  /// per unit of weight — so every read of it must de-duplicate.
  ///
  /// Returns an empty session when the pool cannot support a quiz, i.e. when it
  /// holds fewer than two distinct authors and no question would be answerable.
  QuizSession build({
    required List<Quote> candidates,
    required List<Quote> drawPool,
  }) {
    final answerable = candidates
        .where((Quote q) => quoteAuthorLabel(q).trim().isNotEmpty)
        .toList();
    final authors = answerable.map(quoteAuthorLabel).toSet();

    if (answerable.isEmpty || authors.length < 2) {
      return QuizSession.empty();
    }

    final usedQuoteIds = <String>{};
    final selected = <Quote>[];

    for (final MapEntry<String, int> bucket
        in _questionsPerDifficulty.entries) {
      final byDifficulty = drawPool
          .where((Quote q) => normalizedDifficulty(q) == bucket.key)
          .toList();
      selected.addAll(_drawDistinct(byDifficulty, bucket.value, usedQuoteIds));
    }

    // Buckets can come up short on a small or heavily filtered pool; top up from
    // everything left over so a run still gets a full set of questions.
    if (selected.length < kQuizQuestionCount) {
      selected.addAll(
        _drawDistinct(
          drawPool,
          kQuizQuestionCount - selected.length,
          usedQuoteIds,
        ),
      );
    }

    selected.shuffle(_random);

    return QuizSession(
      questions: selected
          .map((Quote quote) => _buildQuestion(quote, answerable))
          .toList(),
      currentIndex: 0,
      isComplete: false,
    );
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

  QuizQuestion _buildQuestion(Quote quote, List<Quote> candidates) {
    final correct = quoteAuthorLabel(quote);
    final options = <String>[correct, ..._pickDistractors(quote, candidates)]
      ..shuffle(_random);

    return QuizQuestion(
      quote: quote,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  /// Picks distinct wrong authors. Contemporaries and authors writing on the
  /// same themes come first, so the options are worth thinking about instead of
  /// being separable at a glance.
  List<String> _pickDistractors(Quote quote, List<Quote> candidates) {
    final correct = quoteAuthorLabel(quote);
    final themes = quote.category.map((String c) => c.toLowerCase()).toSet();

    final related = <String>{};
    final others = <String>{};

    for (final Quote other in candidates) {
      final author = quoteAuthorLabel(other);
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

    final wanted = kQuizOptionCount - 1;
    final distractors = <String>[];

    for (final Set<String> tier in <Set<String>>[related, others]) {
      if (distractors.length >= wanted) {
        break;
      }
      final tierList = tier.toList()..shuffle(_random);
      distractors.addAll(tierList.take(wanted - distractors.length));
    }

    // Deliberately no padding loop: if the pool holds fewer than three other
    // authors, the question simply shows fewer options rather than spinning.
    return distractors;
  }

  static String normalizedDifficulty(Quote quote) {
    final raw = quote.difficulty.trim().toLowerCase();
    return _difficultyAliases[raw] ?? 'intermediate';
  }
}
