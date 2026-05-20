import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/supabase_auth_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/purchases_service.dart';
import '../constants/settings_keys.dart';
import '../../domain/providers/repository_providers.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../domain/providers/daily_content_provider.dart';

/// Stream des aktüllen Auth-Status
final supabaseAuthStateProvider = StreamProvider<AuthUser?>((ref) {
  final service = SupabaseAuthService();
  return service.authStateChanges();
});

/// Ist der Benutzer angemeldet?
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(supabaseAuthStateProvider);
  return authState.whenData((user) => user != null).value ?? false;
});

/// Aktülle User-ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(supabaseAuthStateProvider);
  return authState.whenData((user) => user?.id).value;
});

/// Aktülle User-Email
final currentUserEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(supabaseAuthStateProvider);
  return authState.whenData((user) => user?.email).value;
});

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  final _service = SupabaseAuthService();

  void _init() {
    _service.authStateChanges().listen(
      (user) async {
        state = AsyncValue.data(user);
        // Invalidate daily content so it reloads with the new user's profile/cache
        _ref.invalidate(dailyContentProvider);
        try {
          if (user != null) {
            await _setGuestModeEnabled(false);
            // On login: merge local favorites to cloud and pull cloud favorites back locally
            try {
              await _onLogin(user.id);
            } catch (e) {
              // Log but don't fail - favorites sync is non-blocking
              debugPrint('Favorites sync error: $e');
            }
            // Link RevenueCat to this user id
            try {
              await PurchasesService.instance.logIn(user.id);
            } catch (e) {
              // non-fatal: log and continue
              debugPrint('RevenueCat login error: $e');
            }
          }
        } catch (e) {
          // ignore sync errors here but log if needed
          debugPrint('Auth state change error: $e');
        }
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );
  }

  Future<void> _onLogin(String userId) async {
    final quoteRepo = _ref.read(quoteRepositoryProvider);

    // collect local favorite ids (quote.id strings)
    final localFavQuotes = await quoteRepo.watchFavorites().first;
    final localFavoriteIds = localFavQuotes.map((q) => q.id).toList();

    // sync local -> cloud
    await SupabaseSyncService().syncLocalFavoritesToCloud(
      userId: userId,
      localFavoriteIds: localFavoriteIds,
    );

    // fetch cloud favorites and ensure local contains them
    final cloud = await SupabaseSyncService().fetchFavoritesFromCloud(userId);
    final missingLocal = cloud
        .where((id) => !localFavoriteIds.contains(id))
        .toList();
    for (final quoteId in missingLocal) {
      try {
        await quoteRepo.addFavorite(quoteId);
      } catch (_) {
        // ignore per-item failures
      }
    }

    // Load UserProfile from cloud and restore locally
    try {
      final userProfileNotifier = _ref.read(userProfileProvider.notifier);
      await userProfileNotifier.loadProfileFromCloud(userId);
    } catch (e) {
      // Non-fatal: UserProfile sync failed but user is still logged in
      debugPrint('UserProfile cloud load error: $e');
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _service.signUpWithEmail(email, password);
      // Auth state wird durch authStateChanges automatisch aktualisiert
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _service.signInWithEmail(email, password);
      // Auth state wird durch authStateChanges automatisch aktualisiert
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _service.signInWithGoogle();
      // Auth state wird durch authStateChanges automatisch aktualisiert
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _service.resetPassword(email);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> _setGuestModeEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SettingsKeys.guestModeEnabled, enabled);
    } catch (e) {
      debugPrint('Guest mode persistence error: $e');
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
      return AuthController(ref);
    });
