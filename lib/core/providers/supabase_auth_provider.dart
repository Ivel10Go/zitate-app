import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/supabase_auth_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/purchases_service.dart';
import '../constants/settings_keys.dart';
import 'purchases_provider.dart';
import '../../domain/providers/repository_providers.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../domain/providers/daily_content_provider.dart';

/// Auth-Status der App.
///
/// Leitet bewusst von [authControllerProvider] ab statt ein zweites Abo auf
/// `authStateChanges()` zu öffnen. Vorher liefen beide Abos parallel, und
/// verschiedene Screens lasen verschiedene Quellen — bei Login/Logout konnten
/// sie kurzzeitig widersprüchliche Zustände anzeigen.
final supabaseAuthStateProvider = Provider<AsyncValue<AuthUser?>>((ref) {
  return ref.watch(authControllerProvider);
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

/// Ergebnis einer Registrierung aus Sicht der UI.
enum SignUpOutcome {
  /// Konto angelegt und Session aktiv.
  signedIn,

  /// Konto angelegt, aber die E-Mail muss noch bestätigt werden.
  confirmationRequired,

  /// Registrierung fehlgeschlagen; Fehler liegt im Controller-State.
  failed,
}

final googleOnboardingPendingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(SettingsKeys.pendingGoogleOnboarding) ?? false;
});

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  final _service = SupabaseAuthService();

  /// Tracks the last observed user id so we only react to real identity
  /// changes (login/logout) and ignore repeated events for the same session
  /// such as token refreshes. Invalidating on every event resets the home
  /// screen's daily content back to a loading state and made it appear as if
  /// quotes only loaded after a manual pull-to-refresh.
  bool _sawFirstEvent = false;
  String? _lastUserId;

  void _init() {
    _service.authStateChanges().listen(
      (user) async {
        final previousUserId = _lastUserId;
        final identityChanged = !_sawFirstEvent || previousUserId != user?.id;
        _sawFirstEvent = true;
        _lastUserId = user?.id;

        state = AsyncValue.data(user);

        if (!identityChanged) {
          return;
        }

        // Only reload daily content when the signed-in user actually changes
        // (login or logout), not on every token refresh / session replay.
        _ref.invalidate(dailyContentProvider);

        try {
          // Login side effects (favorites merge, cloud profile restore,
          // RevenueCat linking) must only run once per real login. Running
          // them on every token refresh kept rewriting the user profile,
          // which forced the daily content provider to reload repeatedly.
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
          } else if (previousUserId != null) {
            // Echte Abmeldung (nicht der initiale "kein Nutzer"-Event).
            await _onLogout();
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

  /// Räumt den kontogebundenen Zustand nach einer Abmeldung auf.
  ///
  /// Ohne das behielt das Gerät die RevenueCat-Identität des abgemeldeten
  /// Nutzers — dessen Pro-Entitlement blieb also aktiv — und die Provider für
  /// Profil und Favoriten zeigten weiter dessen Daten.
  Future<void> _onLogout() async {
    try {
      await PurchasesService.instance.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }

    try {
      await _ref.read(entitlementProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Entitlement refresh error: $e');
    }

    _ref.invalidate(userProfileProvider);
  }

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.signUpWithEmail(email, password);
      if (result.needsEmailConfirmation) {
        // Keine Session — der Auth-Stream feuert nicht. Der Zustand muss hier
        // explizit auf "abgemeldet" gesetzt werden, sonst bleibt die UI im
        // Ladezustand hängen.
        state = const AsyncValue.data(null);
        return SignUpOutcome.confirmationRequired;
      }
      // Auth state wird durch authStateChanges automatisch aktualisiert
      return SignUpOutcome.signedIn;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return SignUpOutcome.failed;
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SettingsKeys.pendingGoogleOnboarding, true);
      await _service.signInWithGoogle();
      // Auth state wird durch authStateChanges automatisch aktualisiert
      return true;
    } catch (e, st) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(SettingsKeys.pendingGoogleOnboarding);
      } catch (_) {
        // ignore cleanup errors
      }
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SettingsKeys.pendingGoogleOnboarding);
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
