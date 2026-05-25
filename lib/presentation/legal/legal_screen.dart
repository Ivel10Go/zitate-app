import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/app_decorated_scaffold.dart';

/// Provider/Firma für die Anbieterkennzeichnung.
/// Beispiel: "Musterfirma GmbH".
const String _legalProviderName = String.fromEnvironment('LEGAL_PROVIDER_NAME');

/// Ladungsfähige Anschrift für die Anbieterkennzeichnung.
/// Beispiel: "Musterstraße 12, 12345 Berlin".
const String _legalProviderAddress = String.fromEnvironment(
  'LEGAL_PROVIDER_ADDRESS',
);

/// Kontaktangabe für rechtliche Anfragen.
/// Beispiel: "kontakt@beispiel.de".
const String _legalProviderContact = String.fromEnvironment(
  'LEGAL_PROVIDER_CONTACT',
);

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        child: CustomScrollView(
          slivers: <Widget>[
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
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      'RECHTLICHES',
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
                      'Datenschutz, Haftung und Urheberhinweise für die Nutzung der App.',
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
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLarge,
                AppTheme.spacingLarge,
                AppTheme.spacingLarge,
                AppTheme.spacingXl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(<Widget>[
                  _LegalCard(
                    title: 'DATENSCHUTZ',
                    body:
                        'Diese App speichert Einstellungen, Favoriten und Fortschritt lokal auf dem Gerät. '
                        'Wenn du dich anmeldest, können kontobezogene Daten zur Synchronisierung an Supabase übertragen werden. '
                        'Kontaktangaben im Feedback-Formular sind freiwillig. '
                        'Absturzdiagnosen werden nur gesendet, wenn du sie in den Einstellungen aktivierst.',
                  ),
                  const SizedBox(height: 16),
                  _LegalCard(
                    title: 'HAFTUNGSHINWEIS',
                    body:
                        'Die Inhalte dienen der Information und Bildung und ersetzen keine professionelle Beratung. '
                        'Trotz sorgfältiger Pflege übernehmen wir keine Gewähr für Vollständigkeit, Aktualität oder Eignung einzelner Inhalte für konkrete Zwecke.',
                  ),
                  const SizedBox(height: 16),
                  _LegalCard(
                    title: 'URHEBERRECHT',
                    body:
                        'Zitate und zugehörige Inhalte können urheberrechtlich geschützt sein. '
                        'Nutzung, Weitergabe und kommerzielle Verwertung liegen in der Verantwortung der nutzenden Person. '
                        'Bei berechtigten Hinweisen auf Rechtsverletzungen werden Inhalte geprüft und entfernt.',
                  ),
                  const SizedBox(height: 16),
                  _LegalCard(
                    title: 'ANBIETERKENNZEICHNUNG',
                    body: _providerInfoText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hinweis: Diese Seite ist eine technische Basis und ersetzt keine individuelle Rechtsberatung.',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.red,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: scheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

String get _providerInfoText {
  final providerName = _legalProviderName.trim();
  final providerAddress = _legalProviderAddress.trim();
  final providerContact = _legalProviderContact.trim();
  final hasProviderInfo =
      providerName.isNotEmpty &&
      providerAddress.isNotEmpty &&
      providerContact.isNotEmpty;

  if (hasProviderInfo) {
    return 'Name/Firma: $providerName\n'
        'Anschrift: $providerAddress\n'
        'Kontakt: $providerContact';
  }

  return 'Name/Firma: NICHT KONFIGURIERT\n'
      'Anschrift: NICHT KONFIGURIERT\n'
      'Kontakt: NICHT KONFIGURIERT\n\n'
      'Setze die Werte per Dart-Define: '
      'LEGAL_PROVIDER_NAME, LEGAL_PROVIDER_ADDRESS, LEGAL_PROVIDER_CONTACT.';
}
