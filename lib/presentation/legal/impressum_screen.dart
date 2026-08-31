import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/impressum_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/app_decorated_scaffold.dart';

/// Anbieterkennzeichnung nach § 5 DDG und § 18 Abs. 2 MStV.
///
/// Die Inhalte stammen aus [impressum_config.dart]; noch nicht befüllte Felder
/// werden bewusst sichtbar als Platzhalter markiert statt weggelassen.
class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

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
                      'IMPRESSUM',
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
                      'Angaben gemäß § 5 DDG und § 18 Abs. 2 MStV.',
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
                  if (!kImpressumIsConfigured) ...<Widget>[
                    const _ImpressumWarning(),
                    const SizedBox(height: 16),
                  ],
                  const _ImpressumCard(
                    title: 'DIENSTEANBIETER',
                    entries: <_ImpressumEntry>[
                      _ImpressumEntry('Name / Firma', kLegalProviderName),
                      _ImpressumEntry('Anschrift', kLegalProviderAddress),
                      _ImpressumEntry(
                        'Vertreten durch',
                        kLegalProviderRepresentative,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ImpressumCard(
                    title: 'KONTAKT',
                    entries: <_ImpressumEntry>[
                      _ImpressumEntry('E-Mail', kLegalProviderEmail),
                      _ImpressumEntry('Telefon', kLegalProviderPhone),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ImpressumCard(
                    title: 'REGISTER & UMSATZSTEUER',
                    entries: <_ImpressumEntry>[
                      _ImpressumEntry('Registereintrag', kLegalProviderRegister),
                      _ImpressumEntry(
                        'Umsatzsteuer-ID nach § 27a UStG',
                        kLegalProviderVatId,
                      ),
                    ],
                    footnote:
                        'Nur anzugeben, soweit eine Eintragung bzw. eine '
                        'Umsatzsteuer-Identifikationsnummer tatsächlich besteht.',
                  ),
                  const SizedBox(height: 16),
                  const _ImpressumCard(
                    title: 'AUFSICHTSBEHÖRDE',
                    entries: <_ImpressumEntry>[
                      _ImpressumEntry(
                        'Zuständige Behörde',
                        kLegalProviderSupervisoryAuthority,
                      ),
                    ],
                    footnote:
                        'Nur erforderlich, wenn die angebotene Tätigkeit einer '
                        'behördlichen Zulassung bedarf.',
                  ),
                  const SizedBox(height: 16),
                  const _ImpressumCard(
                    title: 'REDAKTIONELL VERANTWORTLICH',
                    entries: <_ImpressumEntry>[
                      _ImpressumEntry(
                        'Verantwortlich nach § 18 Abs. 2 MStV',
                        kLegalContentResponsible,
                      ),
                    ],
                    footnote:
                        'Erforderlich, weil die App redaktionell ausgewählte und '
                        'kommentierte Inhalte anbietet.',
                  ),
                  const SizedBox(height: 16),
                  _ImpressumCard(
                    title: 'VERBRAUCHERSTREITBEILEGUNG',
                    entries: const <_ImpressumEntry>[],
                    body: kLegalDisputeResolutionParticipation
                        ? 'Wir sind bereit, an einem Streitbeilegungsverfahren vor einer '
                              'Verbraucherschlichtungsstelle teilzunehmen (§ 36 VSBG).'
                        : 'Wir sind nicht bereit und nicht verpflichtet, an '
                              'Streitbeilegungsverfahren vor einer Verbraucherschlichtungs'
                              'stelle teilzunehmen (§ 36 VSBG).',
                  ),
                  const SizedBox(height: 16),
                  const _ImpressumCard(
                    title: 'HAFTUNG FÜR INHALTE UND LINKS',
                    entries: <_ImpressumEntry>[],
                    body:
                        'Für eigene Inhalte sind wir nach den allgemeinen Gesetzen '
                        'verantwortlich. Eine Verpflichtung, übermittelte oder gespeicherte '
                        'fremde Informationen zu überwachen, besteht nach §§ 7 ff. DDG nicht. '
                        'Für Inhalte externer Verweise ist ausschließlich deren Anbieter '
                        'verantwortlich; bei bekannt werdenden Rechtsverletzungen werden '
                        'entsprechende Verweise umgehend entfernt.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hinweis: Diese Seite ist eine technische Vorlage mit Platzhaltern und '
                    'ersetzt keine individuelle Rechtsberatung. Vor Veröffentlichung im '
                    'App Store müssen alle Felder mit den tatsächlichen Angaben befüllt '
                    'und auf die konkrete Rechtsform geprüft werden.',
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

class _ImpressumEntry {
  const _ImpressumEntry(this.label, this.value);

  final String label;
  final String value;
}

class _ImpressumCard extends StatelessWidget {
  const _ImpressumCard({
    required this.title,
    required this.entries,
    this.body,
    this.footnote,
  });

  final String title;
  final List<_ImpressumEntry> entries;
  final String? body;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
        borderRadius: BorderRadius.zero,
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
          const SizedBox(height: 12),
          for (final _ImpressumEntry entry in entries) ...<Widget>[
            Text(
              entry.label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              entry.value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: entry.value.trim() == kImpressumPlaceholder
                    ? AppColors.red
                    : scheme.onSurface,
                height: 1.5,
              ),
            ),
            if (entry != entries.last) const SizedBox(height: 12),
          ],
          if (body != null)
            Text(
              body!,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                color: scheme.onSurface,
                height: 1.6,
              ),
            ),
          if (footnote != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              footnote!,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpressumWarning extends StatelessWidget {
  const _ImpressumWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.red, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        'Dieses Impressum enthält noch Platzhalter. Vor der Veröffentlichung müssen '
        'die rot markierten Felder in lib/core/constants/impressum_config.dart oder '
        'per --dart-define gesetzt werden.',
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.red,
          height: 1.5,
        ),
      ),
    );
  }
}
