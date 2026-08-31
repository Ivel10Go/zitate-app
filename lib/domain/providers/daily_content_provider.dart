import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/pro_launch_config.dart';
import '../../core/providers/supabase_auth_provider.dart';
import '../../data/models/daily_content.dart';
import '../../data/models/quote.dart';
import '../../data/models/thinker_quote.dart';
import '../../data/models/user_profile.dart';
import '../services/daily_content_resolver.dart';
import '../services/personalization_service.dart';
import '../services/quote_rotation_store.dart';
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

/// One store for the whole app: [QuoteRotationStore.record] serializes writes
/// through its own instance, which only helps if every caller shares it.
final quoteRotationStoreProvider = Provider<QuoteRotationStore>((Ref ref) {
  return QuoteRotationStore();
});

const String _cachedDailyContentKey = 'cached_daily_content';
const String _cachedDailyContentDateKey = 'cached_daily_content_date';
const String _cachedFeedKey = 'cached_daily_feed';

String _todayKey([DateTime? now]) {
  final today = now ?? DateTime.now();
  return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
}

/// Signature of the inputs that shape the personalized feed. Baked into the
/// per-day cache key so the feed reacts immediately when interests or the
/// political lens change, but stays stable across rebuilds within a day.
String _feedSignature(UserProfile profile) {
  final interests = <String>[...profile.historicalInterests]..sort();
  return '${profile.politicalLeaning.name}|${interests.join(',')}';
}

Future<List<Quote>?> _readCachedFeed(String userId, String signature) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _todayKey();
    final contentKey = '${_cachedFeedKey}_${userId}_$dateKey';
    final sigKey = '${_cachedFeedKey}_sig_${userId}_$dateKey';

    if (prefs.getString(sigKey) != signature) {
      return null;
    }
    final raw = prefs.getString(contentKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return null;
    }
    final feed = decoded
        .whereType<Map<String, dynamic>>()
        .map(Quote.fromJson)
        .toList(growable: false);
    // A truncated or partly malformed write would otherwise survive as a short
    // (or empty) list, and being non-null it would count as today's feed —
    // pinning the carousel until midnight. Treat it as a miss and re-resolve.
    if (feed.isEmpty || feed.length != decoded.length) {
      return null;
    }
    return feed;
  } catch (_) {
    return null;
  }
}

Future<void> _cacheFeed(
  List<Quote> feed,
  String userId,
  String signature,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _todayKey();
    final contentKey = '${_cachedFeedKey}_${userId}_$dateKey';
    final sigKey = '${_cachedFeedKey}_sig_${userId}_$dateKey';

    await prefs.setString(
      contentKey,
      jsonEncode(feed.map((Quote quote) => quote.toJson()).toList()),
    );
    await prefs.setString(sigKey, signature);
  } catch (_) {
    // Cache is best-effort only.
  }
}

String _serializeDailyContent(DailyContent content) {
  return jsonEncode(
    content.when<String>(
      quote: (quote) => jsonEncode(<String, Object?>{
        'type': 'quote',
        'value': quote.toJson(),
      }),
      thinkerQuote: (quote) => jsonEncode(<String, Object?>{
        'type': 'thinkerQuote',
        'value': <String, Object?>{
          'id': quote.id,
          'author': quote.author,
          'author_type': quote.authorType,
          'text_de': quote.textDe,
          'source': quote.source,
          'year': quote.year,
          'image_url': quote.imageUrl,
        },
      }),
    ),
  );
}

DailyContent? _deserializeDailyContent(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! String) {
      return null;
    }

    final payload = jsonDecode(decoded);
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final type = payload['type'] as String?;
    final value = payload['value'];
    if (value is! Map<String, dynamic>) {
      return null;
    }

    switch (type) {
      case 'quote':
        return DailyContent.quote(quote: Quote.fromJson(value));
      case 'thinkerQuote':
        return DailyContent.thinkerQuote(quote: ThinkerQuote.fromJson(value));
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

Future<void> _cacheDailyContent(DailyContent content, String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final userContentKey = '${_cachedDailyContentKey}_${userId}_$dateKey';
    final userDateKey = '${_cachedDailyContentDateKey}_${userId}_$dateKey';

    await prefs.setString(userContentKey, _serializeDailyContent(content));
    await prefs.setString(userDateKey, dateKey);
  } catch (_) {
    // Cache is best-effort only.
  }
}

/// Removes all cached daily-content entries (every user/day). Call this when
/// the inputs that shape the daily selection change — interests, political
/// leaning or the home content format — so that invalidating
/// [dailyContentProvider] re-resolves fresh content instead of returning the
/// already cached pick for today.
Future<void> clearDailyContentCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where(
          (String key) =>
              key.startsWith(_cachedDailyContentKey) ||
              key.startsWith(_cachedFeedKey),
        )
        .toList(growable: false);
    for (final String key in keys) {
      await prefs.remove(key);
    }
  } catch (_) {
    // Best-effort only.
  }
}

Future<DailyContent?> _readCachedDailyContent(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final userContentKey = '${_cachedDailyContentKey}_${userId}_$dateKey';
    final userDateKey = '${_cachedDailyContentDateKey}_${userId}_$dateKey';
    final cachedDate = prefs.getString(userDateKey);

    // Only return cached content if it's from today
    if (cachedDate == dateKey) {
      return _deserializeDailyContent(prefs.getString(userContentKey));
    }
    return null;
  } catch (_) {
    return null;
  }
}

final dailyContentProvider = FutureProvider<DailyContent>((Ref ref) async {
  // Get current user ID for per-user caching
  final currentUserId = ref.watch(currentUserIdProvider) ?? 'anonymous_device';

  final cachedContent = await _readCachedDailyContent(currentUserId);
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
      await _cacheDailyContent(content, currentUserId);
      return content;
    }
  } catch (_) {
    final cachedContent = await _readCachedDailyContent(currentUserId);
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
  final currentUserId = ref.watch(currentUserIdProvider) ?? 'anonymous_device';

  // Stable per user, per day and per preference signature: swiping away and
  // back returns the same feed, and the rotation history is only advanced once
  // per day instead of on every rebuild.
  final signature = _feedSignature(profile);
  final cached = await _readCachedFeed(currentUserId, signature);
  if (cached != null) {
    return cached;
  }

  final rotationStore = ref.watch(quoteRotationStoreProvider);
  final recentIds = await rotationStore.recentIds(currentUserId);

  final feed = await resolver.resolvePremiumQuoteFeed(
    quoteRepository: quoteRepository,
    appMode: appMode,
    profile: profile,
    count: kDailyFeedQuoteCount,
    excludeIds: recentIds,
  );

  if (feed.isNotEmpty) {
    await rotationStore.record(
      currentUserId,
      feed.map((Quote quote) => quote.id),
    );
    await _cacheFeed(feed, currentUserId, signature);
  }
  return feed;
});
