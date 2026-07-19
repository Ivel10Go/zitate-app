// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/supabase_auth_provider.dart';
import '../../core/constants/settings_keys.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_decorated_scaffold.dart';

class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.guestModeEnabled, true);
    if (!mounted) {
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    ref.listen(authControllerProvider, (previous, next) {
      final user = next.asData?.value;
      if (user == null || !mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/onboarding');
        }
      });
    });

    // Feste Column mit Expanded-Platzhalter lief über, sobald der Inhalt höher
    // als der Viewport wurde (kleine Geräte, große System-Schriftgröße): der
    // Platzhalter bekam 0 Höhe und der untere Block wurde abgeschnitten.
    // LayoutBuilder + scrollbarer Mindesthöhen-Container behält die Verteilung
    // bei genug Platz und macht die Seite sonst scrollbar.
    return AppDecoratedScaffold(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, -0.18),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: FadeTransition(
                          opacity: _controller,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: AppColors.red.withValues(
                                      alpha: 0.24,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    'assets/branding/Zitate App.png',
                                    fit: BoxFit.contain,
                                    // Die Quelldatei ist 3,5 MB groß und wird hier auf
                                    // 40 dp dargestellt. Ohne cacheWidth dekodiert
                                    // Flutter sie in voller Auflösung in den Speicher.
                                    cacheWidth: 160,
                                    // Fehlt das Asset, zeigt Flutter sonst ein rotes
                                    // Fehler-Widget mitten auf dem Startbildschirm.
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.menu_book_outlined,
                                        color: AppColors.red,
                                        size: 24,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Quotidian',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 40,
                                height: 2,
                                color: AppColors.red,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Entdecke die Weisheit großer Denker.',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _googleLoading
                                      ? null
                                      : () async {
                                          setState(() => _googleLoading = true);
                                          try {
                                            await ref
                                                .read(
                                                  authControllerProvider
                                                      .notifier,
                                                )
                                                .signInWithGoogle();
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  authErrorMessage(e),
                                                ),
                                              ),
                                            );
                                            setState(
                                              () => _googleLoading = false,
                                            );
                                            return;
                                          }

                                          if (!mounted) {
                                            return;
                                          }

                                          setState(
                                            () => _googleLoading = false,
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: scheme.outline,
                                      width: 1,
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  child: _googleLoading
                                      ? SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.red,
                                                ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFDB4437),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Text(
                                                'G',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'MIT GOOGLE FORTFAHREN',
                                              style: GoogleFonts.ibmPlexSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onSurface,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.18),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.2,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            FilledButton(
                              onPressed: () => context.go('/login'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'ANMELDEN',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () => context.go('/register'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: scheme.outline,
                                  width: 1,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                'REGISTRIEREN',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.red,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _continueAsGuest,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                foregroundColor: scheme.onSurfaceVariant,
                              ),
                              child: Text(
                                'OHNE LOGIN FORTFAHREN',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Du kannst jederzeit später ein Konto anlegen.',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
