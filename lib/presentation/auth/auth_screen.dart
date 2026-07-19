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

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final authController = ref.read(authControllerProvider.notifier);

    final SignUpOutcome outcome;
    if (widget.isSignUp) {
      outcome = await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      final signedIn = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      outcome = signedIn ? SignUpOutcome.signedIn : SignUpOutcome.failed;
    }

    if (!mounted) {
      return;
    }

    if (outcome != SignUpOutcome.failed) {
      if (outcome == SignUpOutcome.confirmationRequired) {
        setState(() => _loading = false);
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
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
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                  ),
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

      // Kein invalidate/delay mehr: der Auth-Stream hat den Controller-State
      // bereits gesetzt. Ein Neuaufbau würde ihn nur zurück auf `loading`
      // werfen und den Auth-Gate kurz ins Leere laufen lassen.
      if (mounted) {
        // Registrierung → immer Onboarding.
        // Login → über den Auth-Gate, der anhand des Profils entscheidet, ob
        // das Onboarding noch aussteht oder direkt Home angezeigt wird.
        context.go(widget.isSignUp ? '/onboarding' : '/auth-gate');
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
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
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

  Future<void> _showResetPasswordDialog() async {
    final resetEmailCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Passwort zurücksetzen'),
          content: TextField(
            controller: resetEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-Mail Adresse',
              hintText: 'deine@email.com',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final email = resetEmailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte gib eine gültige E-Mail ein'),
                    ),
                  );
                  return;
                }

                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .resetPassword(email);

                  if (!mounted) return;
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Passwort-Reset-Link wurde gesendet. Bitte überprüfe dein Postfach.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
                }
              },
              child: const Text('Senden'),
            ),
          ],
        );
      },
    );

    resetEmailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppDecoratedScaffold(
      child: Column(
        children: <Widget>[
          // Masthead im Editorial-Stil, analog zu Home/Onboarding.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'QUOTIDIAN · KONTO',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isSignUp ? 'REGISTRIEREN' : 'ANMELDEN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                Divider(
                  color: scheme.primary.withValues(alpha: 0.25),
                  height: 1,
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
                          color: AppColors.red.withValues(alpha: 0.06),
                          border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.ibmPlexSans(
                            color: AppColors.red,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _fieldLabel('E-MAIL'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'deine@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
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
                    const SizedBox(height: 16),
                    _fieldLabel('PASSWORT'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _passwordController,
                      hint: widget.isSignUp
                          ? 'Mindestens 6 Zeichen'
                          : 'Dein Passwort',
                      obscureText: !_passwordVisible,
                      enabled: !_loading,
                      showVisibilityToggle: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Passwort ist erforderlich';
                        }
                        if (v.length < 6) {
                          return 'Passwort muss mindestens 6 Zeichen lang sein';
                        }
                        return null;
                      },
                    ),
                    if (widget.isSignUp) ...<Widget>[
                      const SizedBox(height: 16),
                      _fieldLabel('PASSWORT BESTÄTIGEN'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _passwordConfirmController,
                        hint: 'Passwort wiederholen',
                        obscureText: !_passwordVisible,
                        enabled: !_loading,
                        showVisibilityToggle: true,
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
                    if (!widget.isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : _showResetPasswordDialog,
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
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
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(color: scheme.outline, height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ODER',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: scheme.outline, height: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _GoogleSignInButton(
                      label: widget.isSignUp
                          ? 'MIT GOOGLE REGISTRIEREN'
                          : 'MIT GOOGLE ANMELDEN',
                      isLoading: _loading,
                      onTap: _signInWithGoogle,
                    ),
                    if (widget.isSignUp) ...<Widget>[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
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
                    ],
                    const SizedBox(height: 16),
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
                    Center(
                      child: TextButton(
                        onPressed: _loading ? null : _continueAsGuest,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: scheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    bool enabled = true,
    bool showVisibilityToggle = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.ibmPlexSans(fontSize: 13, color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.ibmPlexSans(
          fontSize: 13,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        suffixIcon: showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              )
            : null,
        filled: true,
        fillColor: enabled ? scheme.surface : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.red, width: 1.2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.red, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.red, width: 1.2),
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
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: scheme.outline, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: isLoading
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.onSurface),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
    );
  }
}
