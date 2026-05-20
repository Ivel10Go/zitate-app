import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_auth_provider.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/providers/user_profile_provider.dart';

/// Completion Page: Zeigt Synchronisierungs-Status nach Onboarding
///
/// Diese Page:
/// 1. Speichert die User-Profile lokal & cloud
/// 2. Zeigt einen schönen Loading-State
/// 3. Invalidiert Provider für frische Daten
/// 4. Wird vom OnboardingScreen aufgerufen
class OnboardingCompletionPage extends ConsumerStatefulWidget {
  const OnboardingCompletionPage({
    super.key,
    required this.onCompleted,
    required this.selectedInterests,
    required this.politicalLeaning,
  });

  final VoidCallback onCompleted;
  final List<String> selectedInterests;
  final String politicalLeaning;

  @override
  ConsumerState<OnboardingCompletionPage> createState() =>
      _OnboardingCompletionPageState();
}

class _OnboardingCompletionPageState
    extends ConsumerState<OnboardingCompletionPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _controller.forward();
    _performSync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Führt Profil-Synchronisierung durch
  Future<void> _performSync() async {
    try {
      // Konvertiere String politicalLeaning zu Enum
      final PoliticalLeaning leaning = PoliticalLeaning.values.firstWhere(
        (l) => l.toString().split('.').last == widget.politicalLeaning,
        orElse: () => PoliticalLeaning.neutral,
      );

      // Speichere Profil lokal
      await ref
          .read(userProfileProvider.notifier)
          .saveProfile(
            historicalInterests: widget.selectedInterests,
            politicalLeaning: leaning,
            onboardingCompleted: true,
          );

      // Invalidiere Provider für frische Daten
      ref.invalidate(authControllerProvider);
      ref.invalidate(userProfileProvider);

      // Kleine Verzögerung für UI-Polish
      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() => _completed = true);

        // Auto-callback nach kurzem Display
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          widget.onCompleted();
        }
      }
    } catch (e) {
      debugPrint('Onboarding sync error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Synchronisierung fehlgeschlagen: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon/Status
              ScaleTransition(
                scale: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _hasError
                        ? Colors.red.withValues(alpha: 0.1)
                        : AppColors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _hasError
                        ? Icon(Icons.error_outline, size: 50, color: Colors.red)
                        : _completed
                        ? Icon(
                            Icons.check_circle,
                            size: 50,
                            color: AppColors.red,
                          )
                        : SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.red,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Status Text
              FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _hasError
                          ? 'Fehler bei der Synchronisierung'
                          : 'Profil wird synchronisiert',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasError
                          ? _errorMessage
                          : _completed
                          ? 'Dein Profil ist bereit!'
                          : 'Bitte warte einen Moment...',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Error Retry Button
              if (_hasError) ...[
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    setState(() => _hasError = false);
                    _performSync();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Erneut versuchen',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
