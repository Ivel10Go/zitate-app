import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/supabase_auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/providers/user_profile_provider.dart';

/// AuthGateScreen: Professioneller Einstiegspunkt der App
///
/// Logik:
/// - Überwacht Auth-Status via [supabaseAuthStateProvider]
/// - Nicht authentifiziert → /auth (Auth-Choice)
/// - Authentifiziert + Onboarding done → / (Home)
/// - Authentifiziert + Onboarding NOT done → /onboarding
///
/// Zeigt während des Ladens einen schönen Splash Screen mit Animation
class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(supabaseAuthStateProvider);
    final userProfile = ref.watch(userProfileProvider);
    final profileReady = ref.watch(userProfileReadyProvider);

    return profileReady.when(
      loading: () => _buildSplashScreen(),
      error: (e, st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('[AuthGate] Profile load error: $e');
          context.go('/auth');
        });
        return _buildSplashScreen();
      },
      data: (_) => authState.when(
        // Loading: Zeige Splash Screen mit Animation
        loading: () => _buildSplashScreen(),

        // Error: Zeige Error-Screen und leite zur Auth weiter
        error: (e, st) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('[AuthGate] Auth state error: $e');
            context.go('/auth');
          });
          return _buildSplashScreen();
        },

        // Data: Logik für Navigation basierend auf Auth-Status
        data: (authUser) {
          // Nicht authentifiziert → Zur Auth-Choice Screen
          if (authUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/auth');
            });
            return _buildSplashScreen();
          }

          // Authentifiziert: Prüfe Onboarding-Status vom User Profile
          final hasCompletedOnboarding =
              userProfile.onboardingCompleted &&
              userProfile.historicalInterests.isNotEmpty;

          if (!hasCompletedOnboarding) {
            // Onboarding NOT completed → Zur Onboarding Screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/onboarding');
            });
            return _buildSplashScreen();
          }

          // Alles OK: Zur Home Screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          return _buildSplashScreen();
        },
      ),
    );
  }

  /// Baut einen schönen Splash Screen mit Animations-Effekt
  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/App Icon mit Fade-In Animation
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '📚',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Name mit Fade-In
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
                ),
              ),
              child: Text(
                'Zitatatlas',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle mit Fade-In
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 0.7).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
                ),
              ),
              child: Text(
                'Große Denker, große Zitate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.red.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
