import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/pro_launch_config.dart';
import '../../core/providers/purchases_provider.dart';
import '../../core/services/account_privacy_service.dart';
import '../../core/providers/supabase_auth_provider.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../domain/providers/repository_providers.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final isAuth = authState.whenData((u) => u != null).value ?? false;
    final email = authState.whenData((u) => u?.email).value;

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        child: Column(
          children: <Widget>[
            // Back affordance above the shared editorial masthead so the
            // screen matches Home/Settings/Favorites.
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            const EditorialSectionTitle(
              label: 'KONTO',
              title: 'KONTO',
              subtitle: 'Anmeldung, Konto und Datenschutz',
            ),
            Container(height: 1, color: scheme.outline),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingLarge,
                  AppTheme.spacingLarge,
                  AppTheme.spacingLarge,
                  AppTheme.spacingXl,
                ),
                children: <Widget>[
                  _AuthCard(
                    isAuth: isAuth,
                    email: email,
                    context: context,
                    ref: ref,
                  ),
                  if (kProLaunchEnabled) ...<Widget>[
                    SizedBox(height: AppTheme.spacingXl),
                    const _ProCard(),
                  ],
                  SizedBox(height: AppTheme.spacingXl),
                  _PrivacyCard(context: context, ref: ref),
                  if (kDebugMode) ...<Widget>[
                    SizedBox(height: AppTheme.spacingXl),
                    _DebugCard(context: context, ref: ref),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isAuth,
    required this.email,
    required this.context,
    required this.ref,
  });

  final bool isAuth;
  final String? email;
  final BuildContext context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.paperDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAuth ? Icons.verified_user : Icons.person_outline,
                    color: AppColors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AUTHENTIFIZIERUNG',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAuth ? 'Angemeldet' : 'Nicht angemeldet',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: scheme.outline),
            const SizedBox(height: 16),
            if (isAuth) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  border: Border.all(color: scheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'E-Mail',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      email ?? 'Unbekannt',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _AccountActionButton(
                  label: 'ABMELDEN',
                  filled: true,
                  icon: Icons.logout,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Abmelden?'),
                        content: const Text(
                          'Deine lokalen Favoriten werden beibehalten.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Abmelden'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.pop();
                      }
                    }
                  },
                ),
              ),
            ] else ...[
              Text(
                'Erstelle ein Konto, um deine Favoriten zu synchronisieren und auf allen Geräten verfügbar zu haben.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _AccountActionButton(
                  label: 'ANMELDEN / REGISTRIEREN',
                  filled: false,
                  icon: Icons.login,
                  onTap: () => context.push('/auth'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProCard extends ConsumerWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isPro = ref.watch(isProProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPro
                        ? Icons.workspace_premium_rounded
                        : Icons.workspace_premium_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ZITATE APP PRO',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro ? 'Aktiv' : 'Nicht aktiv',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              isPro
                  ? 'Dein Upgrade ist freigeschaltet: personalisierter Feed, kompletter Denkeratlas, Quiz ohne Tageslimit und PDF-Export der Favoriten.'
                  : 'Personalisierter Zitate-Feed, kompletter Denkeratlas, Quiz ohne Tageslimit und PDF-Export der Favoriten.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _AccountActionButton(
                label: isPro ? 'ABO VERWALTEN' : 'PRO FREISCHALTEN',
                filled: !isPro,
                icon: isPro ? Icons.settings_outlined : Icons.arrow_forward,
                onTap: () => context.push('/paywall'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppColors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'DATENSCHUTZ',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.red,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Exportiere oder lösche deine lokalen Nutzerdaten.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: scheme.outline),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _exportPersonalData(context, ref),
                icon: const Icon(Icons.download_outlined),
                label: const Text('DATENAUSZUG EXPORTIEREN'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmDeletePersonalData(context, ref),
                icon: const Icon(Icons.delete_forever_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('LOKALE DATEN LÖSCHEN'),
              ),
            ),
            const SizedBox(height: 12),
            // Die Schaltfläche hieß zuvor "KONTO & LOKALE DATEN LÖSCHEN",
            // löschte aber nie das Supabase-Konto. Die Beschriftung nennt
            // jetzt, was wirklich passiert; für die Kontolöschung selbst gilt
            // der dokumentierte Weg über den Anbieterkontakt.
            Text(
              'Damit werden Favoriten, Einstellungen und lokal gespeicherte '
              'Inhalte auf diesem Gerät entfernt und du wirst abgemeldet. '
              'Dein Konto selbst bleibt bestehen — die vollständige Löschung '
              'des Kontos kannst du über die Kontaktangaben unter '
              '„Rechtliches" anfordern.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10.5,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => context.push('/legal'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Rechtliches & Kontakt',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? AppColors.red : Colors.transparent;
    final border = filled ? AppColors.redDark : scheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: filled ? scheme.surface : scheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: filled ? scheme.surface : scheme.onSurface,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ENTWICKLERWERKZEUGE',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _AccountActionButton(
                label: 'SYNC FAVORITEN',
                filled: false,
                icon: Icons.sync,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Nicht angemeldet')),
                    );
                    return;
                  }

                  final quoteRepo = ref.read(quoteRepositoryProvider);
                  final localFavs = await quoteRepo.watchFavorites().first;
                  final localIds = localFavs.map((q) => q.id).toList();

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Sync gestartet...')),
                  );

                  try {
                    await SupabaseSyncService().syncLocalFavoritesToCloud(
                      userId: userId,
                      localFavoriteIds: localIds,
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Sync erfolgreich')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Fehler: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _AccountActionButton(
                label: 'PROFIL ZURÜCKSETZEN',
                filled: true,
                icon: Icons.restart_alt_rounded,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(userProfileProvider.notifier).resetProfile();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Profil zurückgesetzt')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _exportPersonalData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final quoteRepo = ref.read(quoteRepositoryProvider);
  final authUser = ref.read(authControllerProvider).valueOrNull;
  final favoriteQuotes = await quoteRepo.watchFavorites().first;
  final favoriteIds = favoriteQuotes.map((quote) => quote.id).toList();

  final exportJson = await AccountPrivacyService().buildExportJson(
    authUser: authUser,
    favoriteIds: favoriteIds,
  );

  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final fileName = 'marx_app_datenauszug_$stamp.json';

  await Share.shareXFiles([
    XFile.fromData(
      utf8.encode(exportJson),
      name: fileName,
      mimeType: 'application/json',
    ),
  ], text: 'Datenauszug für Marx App');

  messenger.showSnackBar(
    const SnackBar(content: Text('Datenauszug vorbereitet.')),
  );
}

Future<void> _confirmDeletePersonalData(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Lokale Daten wirklich löschen?'),
        content: const Text(
          'Damit werden lokale Einstellungen, Favoriten, gelesene Inhalte und '
          'Cloud-Favoriten entfernt. Danach wirst du abgemeldet.\n\n'
          'Dein Konto bleibt bestehen und kann weiterhin zur Anmeldung '
          'genutzt werden.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Löschen'),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true) {
    return;
  }

  final authUser = ref.read(authControllerProvider).valueOrNull;
  final quoteRepo = ref.read(quoteRepositoryProvider);
  final syncService = SupabaseSyncService();
  final privacyService = AccountPrivacyService();

  try {
    if (authUser != null) {
      await syncService.clearFavoritesFromCloud(authUser.id);
    }

    await privacyService.clearLocalUserData(quoteRepository: quoteRepo);

    if (authUser != null) {
      await ref.read(authControllerProvider.notifier).signOut();
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Lokale Nutzerdaten wurden gelöscht.')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Löschen fehlgeschlagen: $e')),
    );
  }
}
