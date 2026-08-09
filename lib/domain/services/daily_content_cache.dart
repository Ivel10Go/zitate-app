import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/daily_content.dart';
import '../../data/models/quote.dart';
import '../../data/models/thinker_quote.dart';

/// Shared store for "the pick of the day".
///
/// Both the UI (`dailyContentProvider`) and the home-screen widget's background
/// isolate (`workmanagerCallbackDispatcher`) read and write today's content
/// through here, so whichever of the two resolves first decides what the other
/// shows. Resolving independently on both sides is what let the widget and the
/// home screen drift apart onto different quotes.
///
/// This is used from the background isolate as well, so it must stay free of
/// Riverpod and of anything that needs a `ProviderScope`.
abstract final class DailyContentCache {
  /// Every key starts with this prefix so [clear] can wipe the whole cache.
  static const String keyPrefix = 'cached_daily_content';

  static const String _payloadKey = '${keyPrefix}_payload';
  static const String _dayKey = '${keyPrefix}_day';
  static const String _ownerKey = '${keyPrefix}_owner';

  /// Owner id used while nobody is signed in.
  static const String anonymousOwner = 'anonymous_device';

  static String dayKeyFor(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Today's cached pick, or `null` when nothing has been cached for today.
  ///
  /// Pass [ownerUserId] to require the entry to belong to that user — the
  /// background isolate omits it because it cannot tell who is signed in.
  static Future<DailyContent?> read({
    String? ownerUserId,
    DateTime? now,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dayKey) != dayKeyFor(now ?? DateTime.now())) {
        return null;
      }
      if (ownerUserId != null && prefs.getString(_ownerKey) != ownerUserId) {
        return null;
      }
      return _deserialize(prefs.getString(_payloadKey));
    } catch (_) {
      return null;
    }
  }

  /// The user the cached entry belongs to. The background isolate uses this to
  /// keep ownership stable when it is the one resolving today's pick.
  static Future<String> readOwner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final owner = prefs.getString(_ownerKey);
      if (owner != null && owner.isNotEmpty) {
        return owner;
      }
    } catch (_) {
      // Fall through to the anonymous owner.
    }
    return anonymousOwner;
  }

  static Future<void> write({
    required DailyContent content,
    required String ownerUserId,
    DateTime? now,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The day key is written last: a half-written entry then simply reads as
      // "nothing cached for today" instead of as mismatched content.
      await prefs.setString(_payloadKey, _serialize(content));
      await prefs.setString(_ownerKey, ownerUserId);
      await prefs.setString(_dayKey, dayKeyFor(now ?? DateTime.now()));
    } catch (_) {
      // Cache is best-effort only.
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((String key) => key.startsWith(keyPrefix))
          .toList(growable: false);
      for (final String key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  static String _serialize(DailyContent content) {
    return jsonEncode(
      content.when<Map<String, Object?>>(
        quote: (Quote quote) => <String, Object?>{
          'type': 'quote',
          'value': quote.toJson(),
        },
        thinkerQuote: (ThinkerQuote quote) => <String, Object?>{
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
        },
      ),
    );
  }

  static DailyContent? _deserialize(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final value = payload['value'];
      if (value is! Map<String, dynamic>) {
        return null;
      }

      switch (payload['type'] as String?) {
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
}
