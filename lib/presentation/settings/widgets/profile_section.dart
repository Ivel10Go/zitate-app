import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/icon_circle.dart';
import '../../shared/app_card.dart';
import '../../../core/services/supabase_sync_service.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/providers/daily_content_provider.dart';
import '../../../core/providers/supabase_auth_provider.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../domain/providers/user_profile_provider.dart';

class ProfileSection extends ConsumerWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final interests = availableInterests
        .where(
          (InterestOption option) =>
              profile.historicalInterests.contains(option.id),
        )
        .map((InterestOption option) => option.label)
        .toList();
    final interestsSummary = _formatInterestsSummary(interests);

    return _SettingsGroup(
      title: 'MEIN PROFIL',
      titleColor: AppColors.red,
      topAccentColor: AppColors.red,
      children: <Widget>[
        Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authControllerProvider);
            final isAuth = authState.whenData((u) => u != null).value ?? false;
            final email = authState.whenData((u) => u?.email).value;
            if (isAuth) {
              return _ProfileRow(
                label: 'KONTO',
                value: email ?? 'Angemeldet',
                onTap: () async {
                  // Quick sign out confirmation
                  final doSignOut = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Abmelden?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Abmelden'),
                        ),
                      ],
                    ),
                  );
                  if (doSignOut == true) {
                    await ref.read(authControllerProvider.notifier).signOut();
                  }
                },
              );
            }

            return _ProfileRow(
              label: 'KONTO',
              value: 'Nicht angemeldet',
              onTap: () => _showAuthSheet(context, ref),
            );
          },
        ),
        const SizedBox(height: 12),
        _ProfileRow(
          label: 'Interessen',
          value: interestsSummary,
          onTap: () => _showInterestsSheet(context, ref, profile),
        ),
        const SizedBox(height: 14),
        _ProfileRow(
          label: 'Politische Haltung',
          value: _leaningLabel(profile.politicalLeaning),
          onTap: () => _showLeaningSheet(context, ref, profile),
        ),
        if (kDebugMode) ...<Widget>[
          const SizedBox(height: 12),
          _DebugPremiumToggle(
            enabled: profile.premiumTestEnabled,
            onChanged: (value) => ref
                .read(userProfileProvider.notifier)
                .updatePremiumTestEnabled(value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final userId = ref.read(currentUserIdProvider);
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nicht angemeldet')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final quoteRepo = ref.read(quoteRepositoryProvider);
                final localFavs = await quoteRepo.watchFavorites().first;
                final localIds = localFavs.map((q) => q.id).toList();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Entwickler-Sync gestartet...')),
                );

                try {
                  await SupabaseSyncService().syncLocalFavoritesToCloud(
                    userId: userId,
                    localFavoriteIds: localIds,
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Entwickler-Sync abgeschlossen'),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Sync Fehler: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text(
                'Entwickler: Favoriten synchronisieren (nur Entwicklung)',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _confirmReset(context, ref),
          child: Text(
            'Profil zurücksetzen',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAuthSheet(BuildContext context, WidgetRef ref) async {
    final scheme = Theme.of(context).colorScheme;
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    var isLogin = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final authState = ref.watch(authControllerProvider);
            final loading = authState.isLoading;
            final messenger = ScaffoldMessenger.of(ctx);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isLogin ? 'ANMELDEN' : 'REGISTRIEREN',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'E-Mail'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Passwort'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final success = isLogin
                                  ? await ref
                                        .read(authControllerProvider.notifier)
                                        .signIn(
                                          email: emailCtrl.text.trim(),
                                          password: passCtrl.text.trim(),
                                        )
                                  : await ref
                                        .read(authControllerProvider.notifier)
                                        .signUp(
                                          email: emailCtrl.text.trim(),
                                          password: passCtrl.text.trim(),
                                        );

                              if (!ctx.mounted) return;

                              if (success) {
                                Navigator.of(ctx).pop();
                                return;
                              }

                              final authError = ref
                                  .read(authControllerProvider)
                                  .maybeWhen(
                                    error: (e, _) => e,
                                    orElse: () => null,
                                  );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(authErrorMessage(authError)),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.onSurface,
                        foregroundColor: scheme.surface,
                      ),
                      child: Text(isLogin ? 'ANMELDEN' : 'REGISTRIEREN'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? 'Neu hier? Registrieren'
                          : 'Bereits registriert? Anmelden',
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      hintStyle: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.rule),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${selected.length} ausgewählt',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            selected
                              ..clear()
                              ..addAll(
                                availableInterests.map(
                                  (InterestOption option) => option.id,
                                ),
                              );
                          });
                        },
                        child: const Text('Alle'),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            selected.clear();
                          });
                        },
                        child: const Text('Keine'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 260,
                    child: Builder(
                      builder: (context) {
                        final query = searchQuery.toLowerCase();
                        final visibleInterests = availableInterests
                            .where(
                              (InterestOption option) =>
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final option = visibleInterests[index];
                            final isActive = selected.contains(option.id);
                            return Material(
                              color: isActive
                                  ? AppColors.red.withValues(alpha: 0.1)
                                  : AppColors.paper,
                              child: InkWell(
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
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (selected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Mindestens ein Interesse auswählen.',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
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
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.onSurface,
                        foregroundColor: scheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
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
    final scheme = Theme.of(context).colorScheme;
    var selected = profile.politicalLeaning;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'POLITISCHE HALTUNG',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (final leaning in PoliticalLeaning.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: selected == leaning
                                ? AppColors.ink.withValues(alpha: 0.1)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  selected = leaning;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selected == leaning
                                        ? AppColors.ink
                                        : AppColors.rule,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _leaningLabel(leaning),
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(userProfileProvider.notifier)
                            .updatePoliticalLeaning(selected);
                        ref.invalidate(dailyContentProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.onSurface,
                        foregroundColor: scheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
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

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profil zurücksetzen?'),
          content: const Text(
            'Interessen und politische Haltung werden gelöscht. Onboarding wird erneut gezeigt.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Zurücksetzen'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await ref.read(userProfileProvider.notifier).resetProfile();
    }
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

  String _formatInterestsSummary(List<String> interests) {
    if (interests.isEmpty) {
      return 'Nicht gesetzt';
    }

    if (interests.length <= 2) {
      return interests.join(', ');
    }

    return '${interests.take(2).join(', ')} +${interests.length - 2}';
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(width: 3, height: 28, color: AppColors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
    this.titleColor = AppColors.ink,
    this.topAccentColor,
  });

  final String title;
  final List<Widget> children;
  final Color titleColor;
  final Color? topAccentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icons.person_outline;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconCircle(
                icon: icon,
                background: AppColors.paperDark,
                iconColor: AppColors.red,
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
                      '',
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
    );
  }
}

class _DebugPremiumToggle extends StatelessWidget {
  const _DebugPremiumToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline, width: 1),
        color: AppColors.paper,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Premium-Test (Entwicklung)',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktiviert Premium-Funktionen lokal (z. B. mehrere Zitate).',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    color: AppColors.inkMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
