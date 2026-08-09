import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/pro_launch_config.dart';
import '../../core/providers/purchases_provider.dart';
import '../../core/services/feedback_submission_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/daily_content.dart';
import '../../data/models/user_profile.dart';
import '../../domain/providers/admin_access_provider.dart';
import '../../domain/providers/app_mode_provider.dart';
import '../../domain/providers/daily_content_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../loading/app_loading_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(settingsControllerProvider);
    final appMode = ref.watch(appModeNotifierProvider);
    final isAdmin = ref.watch(adminAccessProvider);
    final isPro = ref.watch(isProProvider);

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        child: Column(
          children: <Widget>[
            EditorialSectionTitle(
              label: 'EINSTELLUNGEN',
              title: 'EINSTELLUNGEN',
              subtitle: 'Steuere, was du täglich siehst und wie du lernst.',
            ),
            Container(height: 1, color: scheme.outline),
            Expanded(
              child: settingsAsync.when(
                data: (settings) {
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingXl,
                    ),
                    children: <Widget>[
                      _SettingsLinkCard(
                        title: 'KONTO',
                        subtitle: 'Anmeldung, Konto und Datenschutz',
                        icon: Icons.person_rounded,
                        onTap: () => context.push('/account'),
                      ),
                      if (kProLaunchEnabled) ...<Widget>[
                        SizedBox(height: AppTheme.spacingLarge),
                        _SettingsLinkCard(
                          title: 'ZITATE APP PRO',
                          subtitle: isPro
                              ? 'Pro aktiv — Abo verwalten'
                              : 'Personalisierter Feed, Denkeratlas & mehr',
                          icon: isPro
                              ? Icons.workspace_premium_rounded
                              : Icons.workspace_premium_outlined,
                          onTap: () => context.push('/paywall'),
                        ),
                      ],
                      SizedBox(height: AppTheme.spacingLarge),
                      _SettingsLinkCard(
                        title: 'ZITAT EINREICHEN',
                        subtitle:
                            'Schlage ein Zitat vor — es wird geprüft und '
                            'ggf. aufgenommen',
                        icon: Icons.edit_note_rounded,
                        onTap: () => context.push('/submit-quote'),
                      ),
                      SizedBox(height: AppTheme.spacingLarge),
                      const _ContentPreferencesGroup(),
                      SizedBox(height: AppTheme.spacingLarge),
                      const _NotificationsGroup(),
                      SizedBox(height: AppTheme.spacingLarge),
                      if (isAdmin) ...<Widget>[
                        _SettingsGroup(
                          title: 'ADMIN',
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'Aktiver Modus',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  _modeLabel(appMode),
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: _SettingsActionButton(
                                label: 'EINREICHUNGEN PRÜFEN',
                                filled: false,
                                onTap: () =>
                                    context.push('/admin/submissions'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _SettingsActionButton(
                                    label: 'ADMIN-BEREICH',
                                    filled: false,
                                    onTap: () => context.push('/admin'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SettingsActionButton(
                                    label: 'MARX MODUS',
                                    filled: true,
                                    onTap: () async {
                                      await ref
                                          .read(
                                            appModeNotifierProvider.notifier,
                                          )
                                          .set(AppMode.adminMarx);
                                      ref.invalidate(dailyContentProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Marx-Modus aktiviert',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      _SettingsGroup(
                        title: 'WARTUNG',
                        children: <Widget>[
                          Text(
                            'Diese Werkzeuge sind für Pflege und Rücksetzung gedacht, nicht für den regulären Tagesgebrauch.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: AppColors.inkLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _SettingsActionButton(
                              label: 'EINFÜHRUNG ERNEUT ANSEHEN',
                              filled: false,
                              onTap: () => context.push('/onboarding'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Onboarding-Status',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    settings.onboardingSeen
                                        ? 'Gesehen'
                                        : 'Offen',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 10,
                                      color: AppColors.inkLight,
                                    ),
                                  ),
                                ],
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => ref
                                      .read(settingsControllerProvider.notifier)
                                      .markOnboardingSeen(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'ANWENDEN',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.red,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Streak zurücksetzen',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Setzt den aktuellen Serien-Status auf null.',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 10,
                                      color: AppColors.inkLight,
                                    ),
                                  ),
                                ],
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => ref
                                      .read(settingsControllerProvider.notifier)
                                      .resetStreak(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.restart_alt_rounded,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                        title: 'RECHTLICHES',
                        children: <Widget>[
                          Text(
                            'Datenschutz, Haftung und Urheberhinweise einsehen und die Absturzdiagnose bewusst aktivieren.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: AppColors.inkLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _SettingsActionButton(
                              label: 'DATENSCHUTZ & RECHTLICHES',
                              filled: false,
                              onTap: () => context.push('/legal'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Absturzdiagnose (Crash-Reports)',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings.crashReportingEnabled
                                          ? 'Aktiviert'
                                          : 'Deaktiviert',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 10,
                                        color: AppColors.inkLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: settings.crashReportingEnabled,
                                onChanged: (enabled) => ref
                                    .read(settingsControllerProvider.notifier)
                                    .setCrashReportingEnabled(enabled),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _BugReportFooter(
                        onTap: () => _showBugReportSheet(context),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: AppInlineLoadingState(
                    title: 'Einstellungen werden geladen',
                    subtitle: 'Profil, Modus und Benachrichtigungen …',
                  ),
                ),
                error: (error, _) => AppInlineErrorState(
                  title: 'Einstellungen konnten nicht geladen werden',
                  message: 'Fehler: $error',
                  onRetry: () => ref.invalidate(settingsControllerProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _modeLabel(AppMode mode) {
  switch (mode) {
    case AppMode.public:
      return 'Für alle';
    case AppMode.adminMarx:
      return 'Marx-Modus';
  }
}

Future<void> _showBugReportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return const _BugReportSheet();
    },
  );
}

Widget _fieldLabel(String text) {
  return Text(
    text,
    style: GoogleFonts.ibmPlexSans(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppColors.red,
      letterSpacing: 1.2,
    ),
  );
}

String _leaningLabel(PoliticalLeaning leaning) {
  switch (leaning) {
    case PoliticalLeaning.left:
      return 'Links';
    case PoliticalLeaning.centerLeft:
      return 'Mitte-Links';
    case PoliticalLeaning.neutral:
      return 'Neutral';
    case PoliticalLeaning.liberal:
      return 'Liberal';
    case PoliticalLeaning.conservative:
      return 'Konservativ';
  }
}

/// Content preferences: topics of interest and political lens. These mirror
/// the onboarding inputs so they can be revisited any time. Changes must NOT
/// re-resolve today's already picked quote — the free tier gets exactly one
/// quote per day; only from tomorrow on do new preferences shape the pick.
/// (The Pro feed via premiumDailyQuotesProvider reacts immediately.)
class _ContentPreferencesGroup extends ConsumerWidget {
  const _ContentPreferencesGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);

    return _SettingsGroup(
      title: 'INHALT',
      children: <Widget>[
        _fieldLabel('THEMEN'),
        const SizedBox(height: 4),
        Text(
          'Wähle Bereiche, die dein täglicher Feed bevorzugen soll.',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 11,
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final InterestOption option in availableInterests)
              _ChoicePill(
                label: '${option.icon}  ${option.label}',
                selected: profile.historicalInterests.contains(option.id),
                onTap: () async {
                  final next = List<String>.from(profile.historicalInterests);
                  if (next.contains(option.id)) {
                    next.remove(option.id);
                  } else {
                    next.add(option.id);
                  }
                  await ref
                      .read(userProfileProvider.notifier)
                      .updateInterests(next);
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        _fieldLabel('AUSRICHTUNG'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final PoliticalLeaning value in PoliticalLeaning.values)
              _ChoicePill(
                label: _leaningLabel(value),
                selected: profile.politicalLeaning == value,
                onTap: () async {
                  await ref
                      .read(userProfileProvider.notifier)
                      .updatePoliticalLeaning(value);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Änderungen wirken sich ab morgen auf dein Tageszitat aus. '
          'Mit Pro erhältst du sofort einen Feed aus mehreren Zitaten zu deinen Interessen.',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 10,
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Daily reminder controls: enable/disable, pick the time, and send a test.
class _NotificationsGroup extends ConsumerWidget {
  const _NotificationsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsControllerProvider).valueOrNull;
    final enabled = settings?.notificationEnabled ?? true;
    final hour = settings?.notificationHour ?? 7;
    final minute = settings?.notificationMinute ?? 0;
    final timeLabel =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return _SettingsGroup(
      title: 'BENACHRICHTIGUNGEN',
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Tägliche Erinnerung',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? 'Aktiviert' : 'Deaktiviert',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: enabled,
              onChanged: (bool value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setNotificationEnabled(value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Uhrzeit',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wann dein Tageszitat erscheint.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
            _ChoicePill(
              label: timeLabel,
              selected: false,
              onTap: enabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: hour, minute: minute),
                      );
                      if (picked != null) {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .setNotificationTime(picked);
                      }
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: scheme.outline),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _SettingsActionButton(
            label: 'TESTBENACHRICHTIGUNG SENDEN',
            filled: false,
            onTap: () async {
              await NotificationService.instance.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Testbenachrichtigung gesendet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.red : scheme.surface,
        border: Border.all(
          color: selected ? AppColors.redDark : scheme.outline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : scheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = _getIconForTitle(title);

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
                  child: Icon(icon, color: AppColors.red, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitleForTitle(title),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[...children],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'INHALT':
        return Icons.tune_rounded;
      case 'BENACHRICHTIGUNGEN':
        return Icons.notifications_outlined;
      case 'ADMIN':
        return Icons.admin_panel_settings_outlined;
      case 'WARTUNG':
        return Icons.build_outlined;
      case 'RECHTLICHES':
        return Icons.gavel_outlined;
      case 'FEHLER & RÜCKMELDUNGEN':
        return Icons.bug_report_outlined;
      default:
        return Icons.settings_outlined;
    }
  }

  String _getSubtitleForTitle(String title) {
    switch (title) {
      case 'INHALT':
        return 'Themen, Ausrichtung und Format';
      case 'BENACHRICHTIGUNGEN':
        return 'Zeitpunkt und Aktivierung';
      case 'ADMIN':
        return 'Admin-Bereich';
      case 'WARTUNG':
        return 'Einführung und Status';
      case 'RECHTLICHES':
        return 'Datenschutz und Hinweise';
      case 'FEHLER & RÜCKMELDUNGEN':
        return 'Probleme berichten';
      default:
        return '';
    }
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: filled ? scheme.surface : scheme.onSurface,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsLinkCard extends StatelessWidget {
  const _SettingsLinkCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, size: 18, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BugReportFooter extends StatelessWidget {
  const _BugReportFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Probleme entdeckt?',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            child: const Text('FEHLER MELDEN'),
          ),
        ],
      ),
    );
  }
}

class _BugReportSheet extends StatefulWidget {
  const _BugReportSheet();

  @override
  State<_BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<_BugReportSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titel und Beschreibung sind erforderlich'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = FeedbackSubmissionService();
      await service.submitBugReport(
        title: _titleController.text,
        description: _descriptionController.text,
        steps: '',
        expected: '',
        contact: _contactController.text.isEmpty
            ? null
            : _contactController.text,
        platform: Theme.of(context).platform == TargetPlatform.iOS
            ? 'iOS'
            : 'Android',
        appVersion: '0.1.0',
        appLocale: Localizations.localeOf(context).toString(),
      );

      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        _contactController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fehlerbericht erfolgreich gesendet! Danke für dein Feedback.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Senden: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingLarge,
          right: AppTheme.spacingLarge,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLarge,
          top: AppTheme.spacingLarge,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outline, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(
                        Icons.bug_report_outlined,
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
                            'FEHLER & RÜCKMELDUNGEN',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Probleme berichten',
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
                Text(
                  'Hilf uns, die App zu verbessern. Melde Fehler oder sende uns Rückmeldung.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.inkLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Fehlertitel',
                    hintText: 'z.B. Widget lädt nicht',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSans(fontSize: 11),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung',
                    hintText: 'Beschreibe das Problem...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSans(fontSize: 11),
                  maxLines: 4,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: 'Kontakt (optional)',
                    hintText: 'deine@email.de',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSans(fontSize: 11),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _SettingsActionButton(
                    label: _isSubmitting
                        ? 'WIRD GESENDET...'
                        : 'FEHLERBERICHT SENDEN',
                    filled: true,
                    onTap: _isSubmitting ? () {} : _submitBugReport,
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
