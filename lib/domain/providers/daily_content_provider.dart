import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_auth_provider.dart';
import '../../data/models/daily_content.dart';
import '../../data/models/quote.dart';
import '../services/daily_content_cache.dart';
import '../services/daily_content_resolver.dart';
import '../services/personalization_service.dart';
import 'app_mode_provider.dart';
import 'repository_providers.dart';
import 'user_profile_provider.dart';

final personalizationServiceProvider = Provider<PersonalizationService>((
  Ref ref,
) {
  return PersonalizationService();
});

final dailyContentResolverProvider = Provider<DailyContentResolver>((Ref ref) {
  return DailyContentResolver(
    personalization: ref.watch(personalizationServiceProvider),
  );
});

/// Removes all cached daily-content entries. Call this when the inputs that
/// shape the daily selection change — interests, political leaning or the home
/// content format — so that invalidating [dailyContentProvider] re-resolves
/// fresh content instead of returning the already cached pick for today.
Future<void> clearDailyContentCache() => DailyContentCache.clear();

final dailyContentProvider = FutureProvider<DailyContent>((Ref ref) async {
  // Get current user ID for per-user caching
  final currentUserId =
      ref.watch(currentUserIdProvider) ?? DailyContentCache.anonymousOwner;

  // The cache is shared with the home-screen widget's background isolate, so
  // reusing it here is what keeps both surfaces on the same quote.
  final cachedContent = await DailyContentCache.read(
    ownerUserId: currentUserId,
  );
  if (cachedContent != null) {
    return cachedContent;
  }

  await ref.watch(initialSeedProvider.future);
  final appMode = ref.watch(appModeNotifierProvider);
  final profile = ref.watch(userProfileProvider);
  final quoteRepository = ref.watch(quoteRepositoryProvider);
  final resolver = ref.watch(dailyContentResolverProvider);
  try {
    final content = await resolver.resolveDailyContentFromRepository(
      quoteRepository: quoteRepository,
      appMode: appMode,
      profile: profile,
    );

    if (content != null) {
      await DailyContentCache.write(
        content: content,
        ownerUserId: currentUserId,
      );
      return content;
    }
  } catch (_) {
    final cachedContent = await DailyContentCache.read(
      ownerUserId: currentUserId,
    );
    if (cachedContent != null) {
      return cachedContent;
    }

    // Fall through to a direct repository fallback so the home screen
    // still renders even if personalization or filtering fails.
  }

  final quotes = await quoteRepository.watchAllQuotes().first;
  if (quotes.isNotEmpty) {
    return DailyContent.quote(quote: quotes.first);
  }

  throw Exception('No quote content available');
});

final premiumDailyQuotesProvider = FutureProvider<List<Quote>>((Ref ref) async {
  await ref.watch(initialSeedProvider.future);
  final appMode = ref.watch(appModeNotifierProvider);
  final profile = ref.watch(userProfileProvider);
  final quoteRepository = ref.watch(quoteRepositoryProvider);
  final resolver = ref.watch(dailyContentResolverProvider);
  final premiumQuoteCount = profile.historicalInterests.length;

  if (premiumQuoteCount <= 0) {
    return <Quote>[];
  }

  return resolver.resolvePremiumQuoteFeed(
    quoteRepository: quoteRepository,
    appMode: appMode,
    profile: profile,
    count: premiumQuoteCount,
  );
});
