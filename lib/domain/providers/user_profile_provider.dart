import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/supabase_sync_service.dart';
import '../../data/models/user_profile.dart';

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile.initial()) {
    _loadFuture = _load();
  }

  late final Future<void> _loadFuture;

  Future<void> get ready => _loadFuture;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(UserProfile.storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      state = UserProfile.fromJsonString(raw);
    } catch (_) {
      state = UserProfile.initial();
    }
  }

  Future<void> saveProfile({
    required List<String> historicalInterests,
    required PoliticalLeaning politicalLeaning,
    QuoteDiscoveryMode quoteDiscoveryMode = QuoteDiscoveryMode.interests,
    bool isAdmin = false,
    bool premiumTestEnabled = false,
    bool onboardingCompleted = true,
    String displayName = '',
    String profileTitle = 'Genosse',
    int avatarIndex = 0,
    String? avatarImageBase64,
    int xp = 0,
    List<String> unlockedBadges = const <String>[],
  }) async {
    final next = UserProfile(
      historicalInterests: historicalInterests,
      politicalLeaning: politicalLeaning,
      quoteDiscoveryMode: quoteDiscoveryMode,
      isAdmin: isAdmin,
      premiumTestEnabled: premiumTestEnabled,
      onboardingCompleted: onboardingCompleted,
      onboardingDate: DateTime.now(),
      displayName: displayName,
      profileTitle: profileTitle,
      avatarIndex: avatarIndex,
      avatarImageBase64: avatarImageBase64,
      xp: xp,
      unlockedBadges: unlockedBadges,
    );

    await _persist(next, syncCloud: true);
  }

  Future<void> updateIdentity({
    String? displayName,
    String? profileTitle,
    int? avatarIndex,
    String? avatarImageBase64,
  }) async {
    final next = state.copyWith(
      displayName: displayName,
      profileTitle: profileTitle,
      avatarIndex: avatarIndex,
      avatarImageBase64: avatarImageBase64,
    );
    await _persist(next, syncCloud: true);
  }

  Future<void> updateProgress({int? xp, List<String>? unlockedBadges}) async {
    final next = state.copyWith(xp: xp, unlockedBadges: unlockedBadges);
    await _persist(next, syncCloud: true);
  }

  Future<void> updateInterests(List<String> interests) async {
    final next = state.copyWith(historicalInterests: interests);
    await _persist(next, syncCloud: true);
  }

  Future<void> updatePoliticalLeaning(PoliticalLeaning leaning) async {
    final next = state.copyWith(politicalLeaning: leaning);
    await _persist(next, syncCloud: true);
  }

  Future<void> updateQuoteDiscoveryMode(QuoteDiscoveryMode mode) async {
    final next = state.copyWith(quoteDiscoveryMode: mode);
    await _persist(next, syncCloud: true);
  }

  Future<void> updateAdminAccess(bool isAdmin) async {
    final next = state.copyWith(isAdmin: isAdmin);
    await _persist(next, syncCloud: true);
  }

  Future<void> updatePremiumTestEnabled(bool enabled) async {
    final next = state.copyWith(premiumTestEnabled: enabled);
    await _persist(next, syncCloud: true);
  }

  Future<void> resetProfile() async {
    final next = UserProfile.initial();
    await _persist(next);
  }

  /// Lade UserProfile aus Cloud und speichere lokal
  /// Wird nach erfolgreichem Login aufgerufen
  Future<void> loadProfileFromCloud(String userId) async {
    try {
      final syncService = SupabaseSyncService();
      final cloudProfile = await syncService.fetchUserProfileFromCloud(userId);

      if (cloudProfile != null) {
        final displayName = cloudProfile['display_name'] as String?;
        final historicalInterests = _parseHistoricalInterests(
          cloudProfile['historical_interests'],
        );
        final politicalLeaning = _parsePoliticalLeaning(
          cloudProfile['political_leaning'] as String?,
        );

        final next = state.copyWith(
          displayName: displayName,
          historicalInterests: historicalInterests,
          politicalLeaning: politicalLeaning,
          onboardingCompleted:
              cloudProfile['onboarding_completed'] as bool? ??
              state.onboardingCompleted,
        );
        await _persist(next);
      }
      // Wenn kein CloudProfile existiert, behält state den aktuellen Wert
    } catch (e) {
      // Log aber nicht fehlschlagen - Cloud-Sync ist nicht kritisch
      debugPrint('Error loading profile from cloud: $e');
    }
  }

  /// Speichere UserProfile zur Cloud
  Future<void> syncToCloud(String userId) async {
    try {
      final syncService = SupabaseSyncService();
      await syncService.syncUserProfileToCloud(
        userId: userId,
        displayName: state.displayName.isEmpty ? null : state.displayName,
        historicalInterests: state.historicalInterests,
        politicalLeaning: state.politicalLeaning.name,
        onboardingCompleted: state.onboardingCompleted,
      );
    } catch (e) {
      // Log aber nicht fehlschlagen - Cloud-Sync ist nicht kritisch
      debugPrint('Error syncing profile to cloud: $e');
    }
  }

  /// Parse political leaning from string
  static PoliticalLeaning _parsePoliticalLeaning(String? value) {
    if (value == null) return PoliticalLeaning.neutral;
    try {
      return PoliticalLeaning.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PoliticalLeaning.neutral,
      );
    } catch (_) {
      return PoliticalLeaning.neutral;
    }
  }

  static List<String> _parseHistoricalInterests(Object? raw) {
    if (raw == null) {
      return <String>[];
    }

    Iterable<dynamic>? values;

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Iterable<dynamic>) {
          values = decoded;
        }
      } catch (_) {
        return <String>[];
      }
    } else if (raw is Iterable<dynamic>) {
      values = raw;
    }

    if (values == null) {
      return <String>[];
    }

    return values
        .map((dynamic value) => value.toString().trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _persist(UserProfile next, {bool syncCloud = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(UserProfile.storageKey, next.toJsonString());
    state = next;

    if (!syncCloud) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    await syncToCloud(userId);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
      (Ref ref) => UserProfileNotifier(),
    );

final userProfileReadyProvider = FutureProvider<void>((Ref ref) {
  return ref.watch(userProfileProvider.notifier).ready;
});
