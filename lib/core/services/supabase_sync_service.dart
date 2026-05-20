import 'package:supabase_flutter/supabase_flutter.dart';

/// Service für Cloud-Sync von Favoriten (Singleton)
class SupabaseSyncService {
  SupabaseSyncService._();
  static final SupabaseSyncService _instance = SupabaseSyncService._();
  factory SupabaseSyncService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  /// Füge Favorit zur Cloud hinzu
  Future<void> addFavoriteToCloud(String userId, String quoteId) async {
    try {
      await _client.from('user_favorites').insert({
        'user_id': userId,
        'quote_id': quoteId,
      });
    } catch (e) {
      throw Exception('Fehler beim Speichern des Favoriten: $e');
    }
  }

  /// Entferne Favorit aus Cloud
  Future<void> removeFavoriteFromCloud(String userId, String quoteId) async {
    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('quote_id', quoteId);
    } catch (e) {
      throw Exception('Fehler beim Löschen des Favoriten: $e');
    }
  }

  /// Hole alle Favoriten aus Cloud
  Future<List<String>> fetchFavoritesFromCloud(String userId) async {
    try {
      final response = await _client
          .from('user_favorites')
          .select('quote_id')
          .eq('user_id', userId);

      final list = response as List<dynamic>;
      return list.map((row) => row['quote_id'].toString()).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Favoriten: $e');
    }
  }

  /// Entferne alle cloud-gespeicherten Favoriten eines Nutzers.
  Future<void> clearFavoritesFromCloud(String userId) async {
    try {
      await _client.from('user_favorites').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Fehler beim Löschen der Cloud-Favoriten: $e');
    }
  }

  /// Synchronisiere lokale Favoriten zur Cloud (Merge: union)
  Future<void> syncLocalFavoritesToCloud({
    required String userId,
    required List<String> localFavoriteIds,
  }) async {
    try {
      final cloudFavorites = await fetchFavoritesFromCloud(userId);

      final newFavorites = localFavoriteIds
          .where((id) => !cloudFavorites.contains(id))
          .toList();

      if (newFavorites.isNotEmpty) {
        final inserts = newFavorites
            .map((quoteId) => {'user_id': userId, 'quote_id': quoteId})
            .toList();
        await _client.from('user_favorites').insert(inserts);
      }
    } catch (e) {
      throw Exception('Fehler beim Sync der Favoriten: $e');
    }
  }

  /// Realtime Stream für Favoriten (falls Supabase Realtime aktiviert)
  Stream<List<String>> favoritesStream(String userId) {
    return _client
        .from('user_favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (data) => List<String>.from(
            data.map((item) => item['quote_id'].toString()),
          ),
        );
  }

  /// Lade UserProfile (Interessen + politische Neigung) aus Cloud
  /// Gibt eine Map zurück mit den Schlüsseln:
  /// - 'historical_interests' (Liste von Strings)
  /// - 'political_leaning' (String)
  /// - 'onboarding_completed' (bool)
  /// oder `null`, wenn der Benutzer nicht existiert
  Future<Map<String, dynamic>?> fetchUserProfileFromCloud(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select(
            'display_name, historical_interests, political_leaning, daily_quote_date, onboarding_completed',
          )
          .eq('id', userId)
          .single();

      return {
        'display_name': response['display_name'] as String?,
        'historical_interests': List<String>.from(
          (response['historical_interests'] as List<dynamic>?) ?? [],
        ),
        'political_leaning':
            response['political_leaning'] as String? ?? 'neutral',
        'daily_quote_date': response['daily_quote_date'] as String?,
        'onboarding_completed':
            response['onboarding_completed'] as bool? ?? true,
      };
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Keine Zeile gefunden - normales Verhalten
        return null;
      }
      throw Exception('Fehler beim Laden des UserProfile: $e');
    } catch (e) {
      throw Exception('Fehler beim Laden des UserProfile: $e');
    }
  }

  /// Speichere UserProfile (Interessen + politische Neigung) zur Cloud
  Future<void> syncUserProfileToCloud({
    required String userId,
    String? displayName,
    required List<String> historicalInterests,
    required String politicalLeaning,
    String? dailyQuoteDate,
    bool? onboardingCompleted,
  }) async {
    try {
      final payload = <String, Object?>{
        'id': userId,
        if (displayName != null) 'display_name': displayName,
        'historical_interests': historicalInterests,
        'political_leaning': politicalLeaning,
        'daily_quote_date': dailyQuoteDate,
        if (onboardingCompleted != null)
          'onboarding_completed': onboardingCompleted,
        'last_synced_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').upsert(payload, onConflict: 'id');
    } catch (e) {
      throw Exception('Fehler beim Speichern des UserProfile: $e');
    }
  }
}
