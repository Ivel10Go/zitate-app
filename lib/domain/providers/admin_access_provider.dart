import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_provider.dart';
import 'user_profile_provider.dart';

/// Liest `profiles.is_admin` des angemeldeten Kontos.
///
/// Das ist die maßgebliche Quelle: Dieselbe Spalte entscheidet in den
/// RLS-Policies, wer Community-Einreichungen lesen und prüfen darf. Sie lässt
/// sich nur außerhalb der App setzen (SQL-Editor / Service-Role) — ein Trigger
/// auf `profiles` verhindert, dass ein Client sie sich selbst setzt.
final remoteAdminFlagProvider = FutureProvider<bool>((Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  try {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('is_admin')
        .eq('id', userId)
        .maybeSingle();
    return (row?['is_admin'] as bool?) ?? false;
  } catch (_) {
    // Offline oder Supabase nicht initialisiert: kein Admin-Zugriff. Das ist
    // die sichere Richtung — die Prüf-Ansicht braucht ohnehin Netz.
    return false;
  }
});

/// Steuert, ob Admin-UI sichtbar ist.
///
/// Lokales Profil-Flag *oder* Server-Flag: Ersteres bleibt für Testgeräte
/// erhalten, Letzteres macht den Bereich für das echte Betreiberkonto
/// erreichbar, ohne dass in der App etwas umgestellt werden muss. Sichtbarkeit
/// ist hier nur Komfort — die Daten schützt die RLS, nicht dieser Wert.
final adminAccessProvider = Provider<bool>((Ref ref) {
  final profile = ref.watch(userProfileProvider);
  if (profile.isAdmin) return true;

  return ref
      .watch(remoteAdminFlagProvider)
      .maybeWhen(data: (isAdmin) => isAdmin, orElse: () => false);
});
