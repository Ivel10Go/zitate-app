import 'dart:async';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the IDs of quotes recently surfaced in the personalized daily feed
/// so the resolver can avoid repeating them for a while.
///
/// Backed by [SharedPreferences] and best-effort: any failure degrades to
/// "no history", so the feed still renders. The history is capped at
/// [_maxHistory] with the most recently shown IDs kept — at
/// `kDailyFeedQuoteCount` quotes per day this spans several weeks before any
/// quote is allowed to recur.
///
/// Use the single instance from `quoteRotationStoreProvider` rather than
/// constructing this per call: [record] is a read-modify-write, and two stores
/// racing on the same key silently drop one side's IDs.
class QuoteRotationStore {
  static const String _keyPrefix = 'daily_feed_recent_ids';
  static const int _maxHistory = 120;

  /// Serializes [record] calls against each other. `premiumDailyQuotesProvider`
  /// re-runs whenever the profile changes, so two feed resolutions can easily
  /// overlap — toggling two interests in quick succession is enough. Both would
  /// read the same stored list and the later write would erase the earlier one's
  /// IDs, letting those quotes come back around the next day.
  Future<void> _pendingWrite = Future<void>.value();

  /// History is per user: the feed cache is already keyed by user id, and a
  /// global key meant that after a logout/login user B's first feed was filtered
  /// by user A's history.
  String _keyFor(String userId) => '${_keyPrefix}_$userId';

  Future<Set<String>> recentIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyFor(userId))?.toSet() ?? <String>{};
    } catch (error, stackTrace) {
      // Degrading to "no history" is correct, but silently and permanently:
      // a failing SharedPreferences presents only as "the feed keeps repeating".
      developer.log(
        'Could not read quote rotation history; feed may repeat quotes',
        name: 'QuoteRotationStore',
        error: error,
        stackTrace: stackTrace,
      );
      return <String>{};
    }
  }

  Future<void> record(String userId, Iterable<String> ids) {
    final fresh = ids
        .where((String id) => id.trim().isNotEmpty)
        .toList(growable: false);
    if (fresh.isEmpty) {
      return Future<void>.value();
    }

    _pendingWrite = _pendingWrite.then((_) => _write(userId, fresh));
    return _pendingWrite;
  }

  Future<void> _write(String userId, List<String> fresh) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyFor(userId);
      final existing = prefs.getStringList(key) ?? <String>[];
      // Newest IDs at the end; drop older duplicates so recency wins.
      final merged = <String>[
        ...existing.where((String id) => !fresh.contains(id)),
        ...fresh,
      ];
      final trimmed = merged.length > _maxHistory
          ? merged.sublist(merged.length - _maxHistory)
          : merged;
      await prefs.setStringList(key, trimmed);
    } catch (error, stackTrace) {
      developer.log(
        'Could not persist quote rotation history',
        name: 'QuoteRotationStore',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
