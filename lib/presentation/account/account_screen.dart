import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/account_privacy_service.dart';
import '../../core/providers/supabase_auth_provider.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../data/models/user_profile.dart';
import '../../domain/providers/repository_providers.dart';
import '../../domain/providers/daily_content_provider.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/political_leaning_parliament_picker.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(userProfileProvider);
    final isAuth = authState.whenData((u) => u != null).value ?? false;
    final email = authState.whenData((u) => u?.email).value;

    final interests = availableInterests
        .where(
          (InterestOption option) =>
              profile.historicalInterests.contains(option.id),
        )
        .map((InterestOption option) => option.label)
        .toList();
    final interestsSummary = _formatInterestsSummary(interests);

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        bottomNavigationBar: const AppNavigationBar(selectedIndex: -1),
        child: CustomScrollView(
          slivers: <Widget>[
            // Masthead (aligned with Settings/Home/Favorites)
            SliverToBoxAdapter(
              child: Container(
                color: scheme.surface,
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingLarge,
                  AppTheme.spacingBase,
                  AppTheme.spacingLarge,
                  AppTheme.spacingBase,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Back button
                    Row(
                      children: <Widget>[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.pop(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'KONTO',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(width: 40, height: 2, color: AppColors.red),
                    const SizedBox(height: 10),
                    Text(
                      'Verwalte dein Konto und deine Personalisierung',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLarge,
                AppTheme.spacingLarge,
                AppTheme.spacingLarge,
                AppTheme.spacingXl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  // Authentication Card
                  _AuthCard(
                    isAuth: isAuth,
                    email: email,
                    context: context,
                    ref: ref,
                  ),
                  SizedBox(height: AppTheme.spacingXl),
                  // Personalization Card
                  _PersonalizationCard(
                    context: context,
                    ref: ref,
                    profile: profile,
                    interestsSummary: interestsSummary,
                  ),
                  SizedBox(height: AppTheme.spacingXl),
                  _NotificationCard(context: context, ref: ref),
                  SizedBox(height: AppTheme.spacingXl),
                  _PrivacyCard(context: context, ref: ref),
                  if (kDebugMode) ...[
                    SizedBox(height: AppTheme.spacingXl),
                    _DebugCard(context: context, ref: ref),
                  ],
                ]),
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

class _PersonalizationCard extends StatelessWidget {
  const _PersonalizationCard({
    required this.context,
    required this.ref,
    required this.profile,
    required this.interestsSummary,
  });

  final BuildContext context;
  final WidgetRef ref;
  final UserProfile profile;
  final String interestsSummary;

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
                  child: Icon(Icons.tune, color: AppColors.red, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PERSONALISIERUNG',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.red,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Passe deinen Tagesinhalt an',
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
            _PersonalizationRow(
              icon: Icons.interests_outlined,
              label: 'Interessen',
              value: interestsSummary,
              onTap: () => _showInterestsSheet(context, ref, profile),
            ),
            const SizedBox(height: 14),
            _PersonalizationRow(
              icon: Icons.public_outlined,
              label: 'Politische Haltung',
              value: _leaningLabel(profile.politicalLeaning),
              onTap: () => _showLeaningSheet(context, ref, profile),
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
                label: const Text('KONTO & LOKALE DATEN LÖSCHEN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: settingsAsync.when(
          data: (settings) {
            return Column(
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
                        Icons.notifications_active_outlined,
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
                            'BENACHRICHTIGUNGEN',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tägliche Erinnerung verwalten',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Tägliche Benachrichtigung',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: settings.notificationEnabled,
                      onChanged: (bool enabled) async {
                        try {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .setNotificationEnabled(enabled);
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Benachrichtigung konnte nicht aktualisiert werden: $e',
                              ),
                            ),
                          );
                        }
                      },
                      activeThumbColor: AppColors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    if (!settings.notificationEnabled) {
                      return;
                    }

                    final selected = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settings.notificationHour,
                        minute: settings.notificationMinute,
                      ),
                    );

                    if (selected == null || !context.mounted) {
                      return;
                    }

                    try {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setNotificationTime(selected);
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Benachrichtigungszeit konnte nicht gespeichert werden: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paperDark,
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Uhrzeit',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: settings.notificationEnabled
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, StackTrace stackTrace) {
            return Text(
              'Benachrichtigungseinstellungen konnten nicht geladen werden.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PersonalizationRow extends StatelessWidget {
  const _PersonalizationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, size: 18, color: scheme.outline),
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

String _formatInterestsSummary(List<String> interests) {
  if (interests.isEmpty) {
    return 'Keine ausgewählt';
  }
  if (interests.length == 1) {
    return interests[0];
  }
  return '${interests.length} Interessen';
}

String _leaningLabel(PoliticalLeaning leaning) {
  switch (leaning) {
    case PoliticalLeaning.left:
      return 'Links';
    case PoliticalLeaning.centerLeft:
      return 'Zentrum-Links';
    case PoliticalLeaning.neutral:
      return 'Neutral';
    case PoliticalLeaning.liberal:
      return 'Liberal';
    case PoliticalLeaning.conservative:
      return 'Konservativ';
  }
}

Future<void> _showInterestsSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  final scheme = Theme.of(context).colorScheme;
  final selected = profile.historicalInterests.toSet();
  var searchQuery = '';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'INTERESSEN BEARBEITEN',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setSheetState(() {
                      searchQuery = value.trim();
                    });
                  },
                  style: GoogleFonts.ibmPlexSans(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Interesse suchen …',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: Builder(
                    builder: (context) {
                      final query = searchQuery.toLowerCase();
                      final visibleInterests = availableInterests
                          .where(
                            (option) =>
                                query.isEmpty ||
                                option.label.toLowerCase().contains(query),
                          )
                          .toList();

                      if (visibleInterests.isEmpty) {
                        return Center(
                          child: Text(
                            'Keine Treffer.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: visibleInterests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = visibleInterests[index];
                          final isActive = selected.contains(option.id);
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                if (isActive) {
                                  selected.remove(option.id);
                                } else {
                                  selected.add(option.id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.red
                                      : AppColors.rule,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Text(option.icon),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isActive
                                        ? Icons.check_box_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: isActive
                                        ? AppColors.red
                                        : AppColors.inkMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            await ref
                                .read(userProfileProvider.notifier)
                                .updateInterests(selected.toList());
                            ref.invalidate(dailyContentProvider);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.onSurface,
                      foregroundColor: scheme.surface,
                    ),
                    child: const Text('SPEICHERN'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _showLeaningSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: PoliticalLeaningParliamentPicker(
          selected: profile.politicalLeaning,
          onSelect: (PoliticalLeaning value) async {
            await ref
                .read(userProfileProvider.notifier)
                .updatePoliticalLeaning(value);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        ),
      );
    },
  );
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
        title: const Text('Daten wirklich löschen?'),
        content: const Text(
          'Damit werden lokale Einstellungen, Favoriten, gelesene Inhalte und Cloud-Favoriten entfernt. Danach wirst du abgemeldet.',
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
      const SnackBar(content: Text('Nutzerdaten wurden gelöscht.')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Löschen fehlgeschlagen: $e')),
    );
  }
}
