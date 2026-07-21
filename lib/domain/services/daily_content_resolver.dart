import 'dart:math';

import '../../data/models/daily_content.dart';
import '../../data/models/quote.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/quote_repository.dart';
import '../../core/utils/german_text_normalizer.dart';
import '../../core/utils/quote_attribution.dart';
import 'personalization_service.dart';

class DailyContentResolver {
  DailyContentResolver({PersonalizationService? personalization})
    : _personalization = personalization ?? PersonalizationService();

  final PersonalizationService _personalization;

  Future<DailyContent?> resolveDailyContentFromRepository({
    required QuoteRepository quoteRepository,
    required AppMode appMode,
    required UserProfile profile,
    DateTime? now,
  }) async {
    final allQuotes = await quoteRepository.watchAllQuotes().first;
    final issueNumber = _issueNumberFor(now ?? DateTime.now());

    return _resolveAsQuote(
      allQuotes: allQuotes,
      appMode: appMode,
      profile: profile,
      issueNumber: issueNumber,
    );
  }

  DailyContent? _resolveAsQuote({
    required List<Quote> allQuotes,
    required AppMode appMode,
    required UserProfile profile,
    required int issueNumber,
  }) {
    final quote = _resolveQuote(
      allQuotes: allQuotes,
      appMode: appMode,
      profile: profile,
      issueNumber: issueNumber,
    );
    if (quote == null) {
      return null;
    }
    return DailyContent.quote(quote: quote);
  }

  Future<List<Quote>> resolvePremiumQuoteFeed({
    required QuoteRepository quoteRepository,
    required AppMode appMode,
    required UserProfile profile,
    required int count,
    Set<String> excludeIds = const <String>{},
    DateTime? now,
  }) async {
    final allQuotes = await quoteRepository.watchAllQuotes().first;
    if (allQuotes.isEmpty || count <= 0) {
      return <Quote>[];
    }

    final issueNumber = _issueNumberFor(now ?? DateTime.now());
    final scopedQuotes = _scopedQuotes(
      allQuotes: allQuotes,
      appMode: appMode,
      profile: profile,
    );
    final candidates = _resolveCandidatePool(
      allQuotes: allQuotes,
      scopedQuotes: scopedQuotes,
      profile: profile,
    );

    if (candidates.isEmpty) {
      return <Quote>[];
    }

    // Prefer quotes that were not shown recently. The full candidate pool stays
    // available as a top-up so the feed is always filled to [count] even when
    // the fresh pool is exhausted (e.g. narrow interests or a small scope).
    final fresh = excludeIds.isEmpty
        ? candidates
        : candidates
              .where((Quote quote) => !excludeIds.contains(quote.id))
              .toList(growable: false);
    final primaryPool = fresh.isEmpty ? candidates : fresh;

    final selected = <Quote>[];
    final seenIds = <String>{};
    final seenContentKeys = <String>{};

    // Fills [selected] up to [count] from [pool], skipping already-picked
    // quotes and duplicate content. Deterministic per day via [seedOffset].
    void addFrom(List<Quote> pool, int seedOffset) {
      if (selected.length >= count) {
        return;
      }
      final weighted = _personalization.getWeightedQuotes(pool, profile);
      if (weighted.isEmpty) {
        return;
      }
      final shuffled = List<Quote>.from(weighted)
        ..shuffle(Random(issueNumber + seedOffset));
      for (final quote in shuffled) {
        if (selected.length >= count) {
          break;
        }
        final contentKey = _quoteContentKey(quote);
        if (seenIds.add(quote.id) && seenContentKeys.add(contentKey)) {
          selected.add(quote);
        }
      }
    }

    // Without interests, just pull diverse quotes (fresh pool first).
    if (profile.historicalInterests.isEmpty) {
      addFrom(primaryPool, 177);
      addFrom(candidates, 178);
      return selected.take(count).toList(growable: false);
    }

    // Interest-driven: one pick per interest from the fresh pool first.
    for (var i = 0; i < profile.historicalInterests.length; i++) {
      if (selected.length >= count) {
        break;
      }
      final interest = profile.historicalInterests[i].trim().toLowerCase();
      if (interest.isEmpty) {
        continue;
      }

      final interestCandidates = primaryPool
          .where((Quote quote) => _matchesInterest(quote, interest))
          .toList();
      if (interestCandidates.isEmpty) {
        continue;
      }

      final weightedInterest = _personalization.getWeightedQuotes(
        interestCandidates,
        profile,
      );
      if (weightedInterest.isEmpty) {
        continue;
      }

      final shuffledInterest = List<Quote>.from(weightedInterest)
        ..shuffle(Random(issueNumber + 73 + i));

      for (final quote in shuffledInterest) {
        final contentKey = _quoteContentKey(quote);
        if (seenIds.add(quote.id) && seenContentKeys.add(contentKey)) {
          selected.add(quote);
          break;
        }
      }
    }

    // Top up to [count]: fresh pool first, then the full pool if still short.
    addFrom(primaryPool, 177);
    addFrom(candidates, 178);

    return selected.take(count).toList(growable: false);
  }

  bool _matchesInterest(Quote quote, String interest) {
    return textMatchesInterest(
      interest: interest,
      texts: <String>[
        quote.textDe,
        quote.source,
        quote.chapter,
        ...quote.category,
      ],
    );
  }

  String _quoteContentKey(Quote quote) {
    final text = quote.textDe.trim().toLowerCase();
    final source = quote.source.trim().toLowerCase();
    return '$source::$text';
  }

  Quote? _resolveQuote({
    required List<Quote> allQuotes,
    required AppMode appMode,
    required UserProfile profile,
    required int issueNumber,
  }) {
    final scopedQuotes = _scopedQuotes(
      allQuotes: allQuotes,
      appMode: appMode,
      profile: profile,
    );

    final candidates = _resolveCandidatePool(
      allQuotes: allQuotes,
      scopedQuotes: scopedQuotes,
      profile: profile,
    );
    final weighted = _personalization.getWeightedQuotes(candidates, profile);
    if (weighted.isEmpty) {
      return null;
    }

    final random = Random(issueNumber + 11);
    final picked = weighted[random.nextInt(weighted.length)];

    // Hard safety guard: conservative users should never receive Marx/Engels.
    if (profile.politicalLeaning == PoliticalLeaning.conservative &&
        _isMarxQuote(picked)) {
      final nonMarxWeighted = weighted
          .where((quote) => !_isMarxQuote(quote))
          .toList();
      if (nonMarxWeighted.isEmpty) {
        return null;
      }
      return nonMarxWeighted[random.nextInt(nonMarxWeighted.length)];
    }

    return picked;
  }

  List<Quote> _resolveCandidatePool({
    required List<Quote> allQuotes,
    required List<Quote> scopedQuotes,
    required UserProfile profile,
  }) {
    if (scopedQuotes.isNotEmpty) {
      return scopedQuotes;
    }

    // Never allow fallback to Marx/Engels for conservative profiles.
    if (profile.politicalLeaning == PoliticalLeaning.conservative) {
      return allQuotes.where((quote) => !_isMarxQuote(quote)).toList();
    }

    return allQuotes;
  }

  List<Quote> _scopedQuotes({
    required List<Quote> allQuotes,
    required AppMode appMode,
    required UserProfile profile,
  }) {
    if (allQuotes.isEmpty) {
      return allQuotes;
    }

    final nonMarxQuotes = allQuotes
        .where((quote) => !_isMarxQuote(quote))
        .toList();

    switch (profile.politicalLeaning) {
      case PoliticalLeaning.left:
      case PoliticalLeaning.centerLeft:
      case PoliticalLeaning.neutral:
        return allQuotes;
      case PoliticalLeaning.liberal:
        final liberalMatches = nonMarxQuotes
            .where((quote) => _matchesAnyLens(quote, _liberalLensTerms))
            .toList();
        if (liberalMatches.isNotEmpty) {
          return liberalMatches;
        }
        if (nonMarxQuotes.isNotEmpty) {
          return nonMarxQuotes;
        }
        return allQuotes;
      case PoliticalLeaning.conservative:
        final conservativeMatches = nonMarxQuotes
            .where((quote) => _matchesAnyLens(quote, _conservativeLensTerms))
            .toList();
        // Primary: Conservative-tagged quotes
        if (conservativeMatches.isNotEmpty) {
          return conservativeMatches;
        }
        // Secondary: All non-Marx, non-Liberal quotes (neutral/centrist)
        final neutralMatches = nonMarxQuotes
            .where((quote) => !_matchesAnyLens(quote, _liberalLensTerms))
            .toList();
        if (neutralMatches.isNotEmpty) {
          return neutralMatches;
        }
        // Tertiary: All non-Marx quotes as fallback
        if (nonMarxQuotes.isNotEmpty) {
          return nonMarxQuotes;
        }
        // Final fallback: everything
        return allQuotes;
    }
  }

  bool _isMarxQuote(Quote quote) {
    final attribution = quoteAuthorLabel(quote).toLowerCase();
    if (attribution.contains('marx') || attribution.contains('engels')) {
      return true;
    }

    final text = normalizeGermanSearchText(
      <String>[
        quote.id,
        quote.series,
        quote.source,
        quote.chapter,
        ...quote.category,
        quote.textDe,
      ].join(' '),
    );

    return _marxMarkerTerms.any((term) => text.contains(term));
  }

  bool _matchesAnyLens(Quote quote, List<String> terms) {
    final text = normalizeGermanSearchText(
      <String>[
        quote.id,
        quote.series,
        quote.source,
        quote.chapter,
        ...quote.category,
        quote.textDe,
      ].join(' '),
    );

    return terms.any((term) => text.contains(term));
  }

  static const List<String> _marxMarkerTerms = <String>[
    'marx',
    'karl marx',
    'engels',
    'friedrich engels',
    'kommunistisch',
    'kommunismus',
    'kommunistisches manifest',
    'manifest der kommunistischen partei',
    'das kapital',
    'deutsche ideologie',
    'grundrisse',
    'lohnarbeit und kapital',
    'brumaire',
    'anti-dühring',
    'anti-duhring',
    'thesen über feuerbach',
    'zur kritik der politischen ökonomie',
    'ursprung der familie',
    'feuerbach und der ausgang der klassischen deutschen philosophie',
  ];

  static const List<String> _liberalLensTerms = <String>[
    'liberal',
    'freiheit',
    'liberty',
    'rechte',
    'plural',
    'markt',
    'individ',
    'aufklärung',
    'verfassung',
    'mill',
  ];

  static const List<String> _conservativeLensTerms = <String>[
    'konservativ',
    'conservative',
    'ordnung',
    'tradition',
    'staat',
    'sicherheit',
    'familie',
    'werte',
    'kontinuit',
    'eigentum',
    'verantwortung',
    'burke',
    'hayek',
  ];

  int _issueNumberFor(DateTime now) {
    final epoch = DateTime(2000, 1, 1);
    return now.difference(epoch).inDays;
  }
}
