import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/share_card_renderer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quote.dart';
import '../../domain/providers/favorites_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/quote_card.dart';
import '../loading/app_loading_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({this.showBottomNavigationBar = true, super.key});

  final bool showBottomNavigationBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final scheme = Theme.of(context).colorScheme;

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        bottomNavigationBar: showBottomNavigationBar
            ? const AppNavigationBar(selectedIndex: 1)
            : null,
        child: Column(
          children: <Widget>[
            EditorialSectionTitle(
              label: 'FAVORITEN',
              title: 'FAVORITEN',
              subtitle:
                  'Deine gespeicherten Lieblingszitate zum Revisieren und Teilen.',
            ),
            Container(height: 1, color: scheme.outline),
            Expanded(
              child: favoritesAsync.when(
                data: (quotes) {
                  if (quotes.isEmpty) {
                    return const _FavoritesEmptyStateCard();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingBase,
                      AppTheme.spacingBase,
                      AppTheme.spacingBase,
                      AppTheme.spacingXl,
                    ),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: AppTheme.spacingMedium,
                        ),
                        child: QuoteCard(
                          quote: quote,
                          onTap: () => _showQuoteInsightSheet(context, quote),
                          onLongPress: () =>
                              _showQuoteInsightSheet(context, quote),
                        ),
                      );
                    },
                  );
                },
                loading: () => const AppInlineLoadingState(
                  title: 'Favoriten werden geladen',
                  subtitle: 'Gespeicherte Zitate werden zusammengestellt ...',
                ),
                error: (error, _) => AppInlineErrorState(
                  title: 'Favoriten konnten nicht geladen werden',
                  message: 'Fehler: $error',
                  onRetry: () => ref.invalidate(favoritesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Favorites intro/tip card removed per scope-reduction request.

Future<void> _showQuoteInsightSheet(BuildContext context, Quote quote) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingLarge,
            AppTheme.spacingBase,
            AppTheme.spacingLarge,
            AppTheme.spacingXl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(width: 44, height: 2, color: AppColors.red),
                const SizedBox(height: 14),
                Text(
                  'VOLLTEXT',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  quote.textDe,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ERKLÄRUNG',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  quote.explanationShort,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'KONTEXT',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quote.explanationLong,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.65,
                  ),
                ),
                if (quote.funFact != null &&
                    quote.funFact!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    'HINWEIS',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quote.funFact!,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppColors.inkLight,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _BroadsheetOutlineButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          ShareCardRenderer().shareQuote(quote, context);
                        },
                        label: 'TEILEN',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BroadsheetButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        label: 'SCHLIESSEN',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FavoritesEmptyStateCard extends StatelessWidget {
  const _FavoritesEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outline, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 34, height: 2, color: AppColors.red),
              const SizedBox(height: 10),
              Text(
                'Noch keine Favoriten',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Markiere ein Zitat mit dem Herzsymbol. Danach erscheint es hier und kann als PDF exportiert werden.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BroadsheetButton extends StatelessWidget {
  const _BroadsheetButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface,
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
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
      ),
    );
  }
}

class _BroadsheetOutlineButton extends StatelessWidget {
  const _BroadsheetOutlineButton({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
