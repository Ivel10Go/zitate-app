import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_decorated_scaffold.dart';

class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppDecoratedScaffold(
      appBar: AppBar(
        title: const Text('Basisfunktionen'),
        backgroundColor: scheme.surface,
      ),
      bottomNavigationBar: null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'BASISFUNKTIONEN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 2, color: AppColors.red),
                const SizedBox(height: 12),
                Text(
                  'Hier sind die Kernfunktionen, die den Launch tragen: lesen, verstehen, teilen und täglich dranbleiben.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outline, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.auto_stories_rounded,
                        size: 18,
                        color: AppColors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Die App ist bereits als täglicher Begleiter nutzbar. Pro soll später die Tiefe erweitern, nicht den Einstieg blockieren.',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _FeatureGrid(),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final features = <_FeatureItem>[
      const _FeatureItem(
        title: 'Zitate + Erklärung',
        description: 'Tageszitate mit direkter Einordnung und Kontext.',
        location: 'Startseite und Detailansicht',
        category: 'Inhalt',
      ),
      const _FeatureItem(
        title: 'Benachrichtigungen',
        description: 'Tägliche Erinnerung zur gewählten Uhrzeit.',
        location: 'Einstellungen',
        category: 'Nutzer',
      ),
      const _FeatureItem(
        title: 'Profil',
        description: 'Interessen, Haltung und Entdeckung steuern.',
        location: 'Einstellungen',
        category: 'Personalisierung',
      ),
      const _FeatureItem(
        title: 'Archiv',
        description: 'Gespeicherte Inhalte jederzeit finden.',
        location: 'Navigation',
        category: 'Sammlung',
      ),
      const _FeatureItem(
        title: 'Teilen',
        description: 'Zitate und Fakten direkt weitergeben.',
        location: 'Startseite und Detailansicht',
        category: 'Interaktion',
      ),
      const _FeatureItem(
        title: 'Vorlesen',
        description: 'Texte per TTS anhören.',
        location: 'Zitat-Detail',
        category: 'Zugänglichkeit',
      ),
      const _FeatureItem(
        title: 'Streak',
        description: 'Tägliche Nutzung sichtbar halten.',
        location: 'Startseite',
        category: 'Motivation',
      ),
      const _FeatureItem(
        title: 'Home Widget',
        description: 'Tagesinhalt direkt auf dem Startbildschirm.',
        location: 'App-Widget',
        category: 'Widget',
      ),
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeatureCard(feature: feature),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _FeatureItem feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.12),
                ),
                child: Text(
                  feature.category,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  feature.title,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.check_rounded, size: 14, color: AppColors.red),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            feature.description,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '📍 ${feature.location}',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
  });

  final String title;
  final String description;
  final String location;
  final String category;
}
