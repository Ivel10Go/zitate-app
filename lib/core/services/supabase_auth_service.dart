import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight auth user model used by the app.
class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;
}

/// Ergebnis einer Registrierung.
class SignUpResult {
  const SignUpResult({required this.user, required this.needsEmailConfirmation});

  final AuthUser user;

  /// `true`, wenn Supabase eine Bestätigungs-E-Mail verschickt hat und noch
  /// keine Session besteht. Die UI muss den Nutzer dann zum Postfach schicken
  /// statt ihn als angemeldet zu behandeln.
  final bool needsEmailConfirmation;
}

/// Service für Supabase Authentication (Singleton)
class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService _instance = SupabaseAuthService._();
  factory SupabaseAuthService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  AuthUser? _mapToAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String?,
    );
  }

  /// Stream für Auth State Changes
  Stream<AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      return _mapToAuthUser(event.session?.user);
    });
  }

  /// Aktueller angemeldeter User
  AuthUser? get currentUser => _mapToAuthUser(_client.auth.currentUser);

  /// Ist der Benutzer angemeldet?
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Email/Passwort Registrierung
  ///
  /// Wenn in Supabase die E-Mail-Verifikation aktiv ist, wird der Benutzer
  /// angelegt, aber es entsteht **keine** Session. Das Ergebnis unterscheidet
  /// beide Fälle, damit die UI nicht fälschlich "angemeldet" signalisiert.
  Future<SignUpResult> signUpWithEmail(String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'marxapp://auth',
      );
      final user = res.user;
      if (user == null) {
        throw Exception('Benutzer konnte nicht registriert werden');
      }
      return SignUpResult(
        user: _mapToAuthUser(user)!,
        needsEmailConfirmation: res.session == null,
      );
    } on AuthException catch (e) {
      // Besseres Error-Handling für Auth-spezifische Fehler
      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        throw Exception(
          'Diese E-Mail-Adresse ist bereits registriert. Bitte melden Sie sich an oder verwenden Sie eine andere E-Mail.',
        );
      }
      throw Exception('Auth Error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Email/Passwort Login
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Anmeldung fehlgeschlagen');
      return _mapToAuthUser(user)!;
    } on AuthException catch (e) {
      throw Exception('Auth Error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Google OAuth Sign-In
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'marxapp://auth',
        scopes: 'email profile',
      );
    } on AuthException catch (e) {
      throw Exception('Google Auth Error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Abmelden
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Passwort zurücksetzen (send reset email)
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'marxapp://auth',
    );
  }
}

String authErrorMessage(Object? error) {
  final raw = (error ?? '').toString().toLowerCase();

  if (raw.contains('invalid login credentials')) {
    return 'Ungueltige Anmeldedaten. Pruefe E-Mail und Passwort oder registriere dich.';
  }
  if (raw.contains('email not confirmed')) {
    return 'Bitte bestaetige zuerst deine E-Mail-Adresse.';
  }
  if (raw.contains('user already registered')) {
    return 'Diese E-Mail ist bereits registriert. Bitte melde dich an.';
  }
  if (raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('timeout')) {
    return 'Netzwerkfehler. Bitte pruefe deine Verbindung und versuche es erneut.';
  }

  return 'Authentifizierung fehlgeschlagen. Bitte versuche es erneut.';
}
