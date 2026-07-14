import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/quote_attribution.dart';
import '../../data/models/quote.dart';
import '../../data/models/user_profile.dart';
import '../services/personalization_service.dart';
import 'repository_providers.dart';
import 'user_profile_provider.dart';

enum ArchiveTab { all }

class ArchiveItem {
  const ArchiveItem.quote(this.quote);

  final Quote quote;
}

final personalizationServiceProvider = Provider<PersonalizationService>((
  Ref ref,
) {
  return PersonalizationService();
});

final archiveQueryProvider = StateProvider<String>((Ref ref) => '');
final archiveTabProvider = StateProvider<ArchiveTab>(
  (Ref ref) => ArchiveTab.all,
);
final archiveThemeFilterProvider = StateProvider<String?>((Ref ref) => null);
final archiveOrientationFilterProvider = StateProvider<String?>(
  (Ref ref) => null,
);

final archivePoolProvider = StreamProvider<List<ArchiveItem>>((Ref ref) async* {
  await ref.watch(initialSeedProvider.future);

  final query = ref.watch(archiveQueryProvider).trim().toLowerCase();
  final selectedTheme = ref.watch(archiveThemeFilterProvider);
  final selectedOrientation = ref.watch(archiveOrientationFilterProvider);
  final profile = ref.watch(userProfileProvider);
  final personalization = ref.watch(personalizationServiceProvider);

  yield* ref.watch(quoteRepositoryProvider).watchAllQuotes().map((
    List<Quote> quotes,
  ) {
    final profileQuotes = _filterQuotesByProfile(quotes, profile);
    final weightedQuotes = personalization.getWeightedQuotes(
      profileQuotes,
      profile,
    );

    final items = weightedQuotes.map(ArchiveItem.quote).toList();

    final dropdownFiltered = items.where((ArchiveItem item) {
      if (selectedTheme != null &&
          !_matchesTheme(item: item, theme: selectedTheme)) {
        return false;
      }

      if (selectedOrientation != null &&
          !_matchesOrientation(item: item, orientation: selectedOrientation)) {
        return false;
      }

      return true;
    }).toList();

    if (query.isEmpty) {
      return dropdownFiltered;
    }

    return dropdownFiltered.where((ArchiveItem item) {
      final quote = item.quote;
      return quote.textDe.toLowerCase().contains(query) ||
          quote.source.toLowerCase().contains(query) ||
          quote.series.toLowerCase().contains(query) ||
          quote.category.any(
            (String category) => category.toLowerCase().contains(query),
          );
    }).toList();
  });
});

final archiveThemeFilterOptionsProvider = Provider<List<String>>((Ref ref) {
  final pool = ref.watch(archivePoolProvider).valueOrNull ?? <ArchiveItem>[];
  final options = <String>{};

  for (final item in pool) {
    options.addAll(_themeTokensForItem(item: item));
  }

  final sorted = options.toList()..sort();
  return sorted;
});

final archiveOrientationFilterOptionsProvider = Provider<List<String>>((
  Ref ref,
) {
  final pool = ref.watch(archivePoolProvider).valueOrNull ?? <ArchiveItem>[];
  final options = <String>{};

  for (final item in pool) {
    options.addAll(_orientationTokensForItem(item: item));
  }

  final sorted = options.toList()..sort();
  return sorted.take(8).toList();
});

final archiveProvider = Provider<AsyncValue<List<ArchiveItem>>>((Ref ref) {
  final poolAsync = ref.watch(archivePoolProvider);

  return poolAsync;
});

Set<String> _themeTokensForItem({required ArchiveItem item}) {
  return <String>{...item.quote.category};
}

Set<String> _orientationTokensForItem({required ArchiveItem item}) {
  final text = <String>[
    item.quote.textDe,
    item.quote.source,
    item.quote.chapter,
    ...item.quote.category,
  ].join(' ').toLowerCase();

  final tokens = <String>{};

  if (_containsAny(text, <String>[
    'arbeit',
    'klasse',
    'revolution',
    'solidar',
    'gewerkschaft',
    'umverteilung',
    'sozial',
  ])) {
    tokens.add('Links');
  }

  if (_containsAny(text, <String>[
    'demokratie',
    'gerecht',
    'reform',
    'teilhabe',
    'chancen',
    'gleichheit',
  ])) {
    tokens.add('Mitte-Links');
  }

  if (_containsAny(text, <String>[
    'freiheit',
    'rechte',
    'individ',
    'aufklärung',
    'markt',
    'plural',
  ])) {
    tokens.add('Liberal');
  }

  if (_containsAny(text, <String>[
    'ordnung',
    'staat',
    'tradition',
    'familie',
    'sicherheit',
    'werte',
  ])) {
    tokens.add('Konservativ');
  }

  if (tokens.isEmpty) {
    tokens.add('Neutral');
  }

  return tokens;
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any((String keyword) => text.contains(keyword));
}

bool _matchesTheme({required ArchiveItem item, required String theme}) {
  final normalized = theme.toLowerCase();
  return item.quote.category.any(
    (String category) => category.toLowerCase().contains(normalized),
  );
}

bool _matchesOrientation({
  required ArchiveItem item,
  required String orientation,
}) {
  return _orientationTokensForItem(item: item).contains(orientation);
}

List<Quote> _filterQuotesByProfile(List<Quote> all, UserProfile profile) {
  return all;
}

// ===== HIERARCHICAL ARCHIVE STRUCTURE: Theme → Philosopher → Quotes =====

/// Selection state for hierarchical archive navigation
final archiveHierarchyThemeProvider = StateProvider<String?>((Ref ref) => null);
final archiveHierarchyPhilosopherProvider = StateProvider<String?>(
  (Ref ref) => null,
);

/// Get all available themes from quotes
final archiveHierarchyAllThemesProvider = Provider<List<String>>((Ref ref) {
  final poolAsync = ref.watch(archivePoolProvider).valueOrNull;
  if (poolAsync == null) return <String>[];

  final themes = <String>{};
  for (final item in poolAsync) {
    themes.addAll(item.quote.category);
  }

  return themes.toList()..sort();
});

/// Get philosophers (authors) that have quotes in the selected theme
final archiveHierarchyPhilosophersProvider = Provider<List<String>>((Ref ref) {
  final selectedTheme = ref.watch(archiveHierarchyThemeProvider);
  if (selectedTheme == null) return <String>[];

  final poolAsync = ref.watch(archivePoolProvider).valueOrNull;
  if (poolAsync == null) return <String>[];

  final philosophers = <String>{};
  for (final item in poolAsync) {
    if (item.quote.category.contains(selectedTheme)) {
      philosophers.add(quoteAuthorLabel(item.quote));
    }
  }

  return philosophers.toList()..sort();
});

/// Get quotes filtered by selected theme and philosopher
final archiveHierarchyQuotesProvider = Provider<List<ArchiveItem>>((Ref ref) {
  final selectedTheme = ref.watch(archiveHierarchyThemeProvider);
  final selectedPhilosopher = ref.watch(archiveHierarchyPhilosopherProvider);
  final query = ref.watch(archiveQueryProvider).trim().toLowerCase();

  final poolAsync = ref.watch(archivePoolProvider).valueOrNull;
  if (poolAsync == null) return <ArchiveItem>[];

  var filtered = poolAsync;

  if (selectedTheme != null) {
    filtered = filtered
        .where((item) => item.quote.category.contains(selectedTheme))
        .toList();
  }

  if (selectedPhilosopher != null) {
    filtered = filtered
        .where((item) => quoteAuthorLabel(item.quote) == selectedPhilosopher)
        .toList();
  }

  if (query.isNotEmpty) {
    filtered = filtered.where((item) {
      final quote = item.quote;
      return quote.textDe.toLowerCase().contains(query) ||
          quote.source.toLowerCase().contains(query) ||
          quote.series.toLowerCase().contains(query) ||
          quote.category.any(
            (category) => category.toLowerCase().contains(query),
          );
    }).toList();
  }

  return filtered;
});
