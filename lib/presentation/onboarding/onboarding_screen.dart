import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/supabase_auth_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../domain/providers/daily_content_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import 'pages/interests_page.dart';
import 'pages/notification_permission_page.dart';
import 'pages/political_leaning_page.dart';
import 'pages/welcome_page.dart';
import 'pages/completion_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;
  final Set<String> _selectedInterests = <String>{};
  PoliticalLeaning _leaning = PoliticalLeaning.neutral;

  static const _pageCount = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == 3 && _selectedInterests.isEmpty) {
      setState(() {});
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _onCompletionFinished() {
    // Nach Completion-Page: navigiere zum Home
    ref.invalidate(authControllerProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(dailyContentProvider);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppDecoratedScaffold(
      child: Column(
        children: <Widget>[
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'ONBOARDING',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_index + 1}/$_pageCount',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 2, color: AppColors.red),
                const SizedBox(height: 10),
                Text(
                  'In wenigen Schritten richtet sich dein Feed auf deine Themen aus.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: scheme.outline,
                  child: FractionallySizedBox(
                    widthFactor: (_index + 1) / _pageCount,
                    child: Container(color: AppColors.red),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SizedBox(height: 10),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int value) {
                setState(() {
                  _index = value;
                });
              },
              children: <Widget>[
                const WelcomePage(),
                NotificationPermissionPage(
                  onAllow: () async {
                    await NotificationService.instance.initialize();
                    if (!mounted) {
                      return;
                    }
                    await _next();
                  },
                  onSkip: _next,
                ),
                InterestsPage(
                  selected: _selectedInterests,
                  onToggle: (String value) {
                    setState(() {
                      if (_selectedInterests.contains(value)) {
                        _selectedInterests.remove(value);
                      } else {
                        _selectedInterests.add(value);
                      }
                    });
                    ref
                        .read(userProfileProvider.notifier)
                        .updateInterests(_selectedInterests.toList());
                  },
                ),
                PoliticalLeaningPage(
                  selected: _leaning,
                  onSelect: (PoliticalLeaning value) {
                    setState(() {
                      _leaning = value;
                    });
                    ref
                        .read(userProfileProvider.notifier)
                        .updatePoliticalLeaning(value);
                  },
                  onSkip: () {
                    setState(() {
                      _leaning = PoliticalLeaning.neutral;
                    });
                    ref
                        .read(userProfileProvider.notifier)
                        .updatePoliticalLeaning(PoliticalLeaning.neutral);
                  },
                ),
                OnboardingCompletionPage(
                  selectedInterests: _selectedInterests.toList(),
                  politicalLeaning: _leaning.toString().split('.').last,
                  onCompleted: _onCompletionFinished,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _index == _pageCount - 1
                ? const SizedBox.shrink() // Keine Buttons auf Completion-Page
                : Row(
                    children: <Widget>[
                      if (_index > 0)
                        Expanded(
                          child: _OutlineActionButton(
                            label: 'ZURÜCK',
                            onTap: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                      if (_index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: _index == _pageCount - 2 ? 'FERTIG' : 'WEITER',
                          onTap: _next,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onSurface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.surface,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
