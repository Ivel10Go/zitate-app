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

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.isSignUp = false});

  final bool isSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;
  String? _errorMessage;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final authController = ref.read(authControllerProvider.notifier);
    final success = widget.isSignUp
        ? await authController.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await authController.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted) {
      return;
    }

    if (success) {
      final currentUser = ref.read(authControllerProvider).valueOrNull;

      if (widget.isSignUp && currentUser == null) {
        setState(() => _loading = false);
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Registrierung erfolgreich'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eine Verifizierungs-Email wurde an deine E-Mail-Adresse gesendet.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bitte klicke auf den Link in der Email, um dein Konto zu bestätigen.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Text('Zur Anmeldung'),
                ),
              ],
            ),
          );
        }
        return;
      }

      ref.invalidate(authControllerProvider);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        context.go(widget.isSignUp ? '/onboarding' : '/');
      }
    } else {
      final authError = ref
          .read(authControllerProvider)
          .maybeWhen(error: (e, _) => e, orElse: () => null);
      setState(() {
        _errorMessage = authErrorMessage(authError);
        _loading = false;
      });
    }

    // Error handling
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final authController = ref.read(authControllerProvider.notifier);

      // Mit Timeout, um zu verhindern, dass der Loading-State hängen bleibt
      final success = await authController.signInWithGoogle().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          return false;
        },
      );

      if (!mounted) {
        return;
      }

      if (success) {
        context.go('/onboarding');
        return;
      } else {
        // Google-Anmeldung fehlgeschlagen
        final error = ref
            .read(authControllerProvider)
            .maybeWhen(error: (e, _) => e, orElse: () => null);

        if (mounted) {
          setState(() {
            _errorMessage = authErrorMessage(error);
            _loading = false;
          });
        }
      }
    } catch (e) {
      // Fehler abfangen
      if (mounted) {
        setState(() {
          _errorMessage =
              'Ein Fehler ist aufgetreten. Bitte versuche es erneut.';
          _loading = false;
        });
      }
    }
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

    return AppDecoratedScaffold(
      child: Column(
        children: <Widget>[
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.isSignUp ? 'REGISTRIEREN' : 'ANMELDEN',
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
                  widget.isSignUp
                      ? 'Erstelle ein Konto, um Inhalte zu speichern und zu synchronisieren.'
                      : 'Melde dich an, um auf dein persönliches Archiv zuzugreifen.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _GoogleSignInButton(
                    label: widget.isSignUp
                        ? 'Mit Google registrieren'
                        : 'Mit Google anmelden',
                    isLoading: _loading,
                    onTap: _signInWithGoogle,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      'OHNE LOGIN FORTFAHREN',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      controller: _emailController,
                      label: 'E-Mail',
                      hint: 'deine@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      showSuffixIcon: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'E-Mail ist erforderlich';
                        }
                        if (!v.contains('@')) {
                          return 'Bitte gib eine gültige E-Mail ein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Passwort',
                      hint: widget.isSignUp
                          ? 'Mindestens 6 Zeichen'
                          : 'Dein Passwort',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_passwordVisible,
                      enabled: !_loading,
                      onObscureToggle: () {
                        setState(() => _passwordVisible = !_passwordVisible);
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Passwort ist erforderlich';
                        }
                        if (v.length < 6) {
                          return 'Passwort muss mindestens 6 Zeichen lang sein';
                        }
                        if (widget.isSignUp &&
                            v != _passwordConfirmController.text) {
                          return 'Passwörter stimmen nicht überein';
                        }
                        return null;
                      },
                    ),
                    if (widget.isSignUp) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _passwordConfirmController,
                        label: 'Passwort bestätigen',
                        hint: 'Passwort wiederholen',
                        icon: Icons.lock_outline_rounded,
                        obscureText: !_passwordVisible,
                        enabled: !_loading,
                        onObscureToggle: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Bestätigung erforderlich';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwörter stimmen nicht überein';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (!widget.isSignUp) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : () {},
                          child: Text(
                            'Passwort vergessen?',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (widget.isSignUp)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          'Nach der Registrierung richtest du dein Profil und deine Interessen ein.',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isSignUp ? 'REGISTRIEREN' : 'ANMELDEN',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() {
                                  _passwordController.clear();
                                  _passwordConfirmController.clear();
                                  _passwordVisible = false;
                                });
                                context.pushReplacement(
                                  widget.isSignUp ? '/login' : '/register',
                                );
                              },
                        child: Text(
                          widget.isSignUp
                              ? 'Bereits ein Konto? Anmelden'
                              : 'Noch kein Konto? Registrieren',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    bool showSuffixIcon = true,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onObscureToggle,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: showSuffixIcon && obscureText != obscureText
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onObscureToggle,
              )
            : null,
        filled: true,
        fillColor: enabled ? scheme.surface : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFDB4437), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.onSurface),
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDB4437),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
