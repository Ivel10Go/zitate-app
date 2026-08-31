import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_loader.dart';
import '../../core/utils/share_card_renderer.dart';
import '../../core/utils/quote_attribution.dart';
import '../../data/models/quote.dart';
import '../../domain/providers/daily_quote_provider.dart';
import '../../domain/providers/favorites_provider.dart';
import '../../domain/providers/repository_providers.dart';
import '../../domain/services/tts_service.dart';
import '../../widgets/adaptive_quote_text.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/category_chip.dart';
import '../loading/app_loading_screen.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  const QuoteDetailScreen({required this.quoteId, super.key});

  final String quoteId;

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  late final TtsService _ttsService;
  bool _audioPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsService = TtsService();
    _initTts();
  }

  Future<void> _initTts() async {
    await _ttsService.init();
    _ttsService.onPlaybackCompleted = () async {
      if (!mounted) {
        return;
      }
      setState(() {
        _audioPlaying = false;
      });
    };
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _showExplanation(Quote quote) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    AppTheme.spacingXs,
                    AppTheme.spacingLarge,
                    AppTheme.spacingXl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ERKLÄRUNG',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        quote.explanationShort,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 15,
                          height: 1.7,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingLarge),
                      Text(
                        'DETAILERLÄUTERUNG',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        quote.explanationLong,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          height: 1.75,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _shareQuote(Quote quote) async {
    await ShareCardRenderer().shareQuote(quote);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quoteId = widget.quoteId;
    final quoteAsync = ref.watch(quoteByIdProvider(quoteId));
    final favoriteAsync = ref.watch(isFavoriteProvider(quoteId));

    return AndroidBackGuard(
      onBlockedPop: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          unawaited(navigator.maybePop());
          return true;
        }

        return false;
      },
      child: AppDecoratedScaffold(
        appBar: null,
        bottomNavigationBar: quoteAsync.when(
          data: (quote) {
            if (quote == null) {
              return const SizedBox.shrink();
            }

            return SafeArea(
              minimum: EdgeInsets.fromLTRB(
                AppTheme.spacingLarge,
                0,
                AppTheme.spacingLarge,
                AppTheme.spacingMedium,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _BroadsheetOutlineButton(
                      onPressed: () => _shareQuote(quote),
                      label: 'TEILEN',
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: _BroadsheetButton(
                      onPressed: () => _showExplanation(quote),
                      label: 'ERKLÄRUNG',
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),
                  favoriteAsync.when(
                    data: (isFavorite) {
                      return SizedBox(
                        width: 48,
                        child: Material(
                          color: isFavorite
                              ? AppColors.red
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final repo = ref.read(quoteRepositoryProvider);
                              if (isFavorite) {
                                await repo.removeFavorite(quoteId);
                              } else {
                                await repo.addFavorite(quoteId);
                              }
                            },
                            child: Center(
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? AppColors.redOnRed
                                    : scheme.onSurface,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        child: quoteAsync.when(
          data: (quote) {
            if (quote == null) {
              return const _DetailEmptyStateCard();
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  color: AppColors.red,
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    AppTheme.spacingBase,
                    AppTheme.spacingLarge,
                    AppTheme.spacingBase,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${quoteAuthorLabel(quote).toUpperCase()} · ${quote.year}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.redOnRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${quote.source} · ${quote.chapter}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          color: AppColors.redOnRed.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox.shrink(),
                if (quote.imageUrl != null && quote.imageUrl!.isNotEmpty)
                  CachedImageLoader(
                    imageUrl: quote.imageUrl!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    cacheConfig: const ImageCacheConfig(
                      cacheDurationDays: 7,
                      maxMemoryCacheSizeMB: 50,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AdaptiveQuoteText(
                        text: quote.textDe,
                        minFontSize: 28,
                        maxFontSize: 42,
                        maxLines: 9,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 14),
                      Container(width: 28, height: 2, color: AppColors.red),
                      const SizedBox(height: 14),
                      Text(
                        '— ${quote.source}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          color: AppColors.inkLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: quote.category
                            .map((String item) => CategoryChip(label: item))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'KURZERKLÄRUNG',
                        body: quote.explanationShort,
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'AUSFÜHRLICHE ERKLÄRUNG',
                        body: quote.explanationLong,
                      ),
                      const SizedBox(height: 16),
                      _AudioExplainerSection(
                        ttsService: _ttsService,
                        explanationShort: quote.explanationShort,
                        explanationLong: quote.explanationLong,
                        audioPlaying: _audioPlaying,
                        onPlayingChanged: (playing) {
                          setState(() {
                            _audioPlaying = playing;
                          });
                        },
                      ),
                      if (quote.funFact != null) ...<Widget>[
                        const SizedBox(height: 16),
                        _SectionCard(title: 'KONTEXT', body: quote.funFact!),
                      ],
                      if (quote.relatedIds.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'VERWANDTE ZITATE',
                          body: quote.relatedIds.join(' · '),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const AppInlineLoadingState(
            title: 'Zitat wird geladen',
            subtitle: 'Detailansicht und Kontext werden vorbereitet ...',
          ),
          error: (error, _) => AppInlineErrorState(
            title: 'Zitat konnte nicht geladen werden',
            message: 'Fehler: $error',
            onRetry: () => ref.invalidate(quoteByIdProvider(quoteId)),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: scheme.onSurface,
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
      ),
    );
  }
}

class _DetailEmptyStateCard extends StatelessWidget {
  const _DetailEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                'Zitat nicht gefunden',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Der Eintrag ist nicht verfügbar oder wurde verschoben. Du kannst zur letzten Ansicht zurückgehen.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('ZURÜCK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quote detail intro/tip card removed per scope-reduction request.

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.surface,
                letterSpacing: 1.0,
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
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioExplainerSection extends StatelessWidget {
  const _AudioExplainerSection({
    required this.ttsService,
    required this.explanationShort,
    required this.explanationLong,
    required this.audioPlaying,
    required this.onPlayingChanged,
  });

  final TtsService ttsService;
  final String explanationShort;
  final String explanationLong;
  final bool audioPlaying;
  final Function(bool) onPlayingChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(
          left: BorderSide(color: Colors.transparent, width: 1),
          right: BorderSide(color: Colors.transparent, width: 1),
          bottom: BorderSide(color: Colors.transparent, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'AUDIO-ERKLÄRUNG',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (audioPlaying) {
                  await ttsService.stop();
                  onPlayingChanged(false);
                  return;
                }
                onPlayingChanged(true);
                await ttsService.speak('$explanationShort $explanationLong');
              },
              icon: Icon(
                audioPlaying
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
              ),
              label: Text(audioPlaying ? 'Stoppen' : 'Anhören'),
            ),
          ],
        ),
      ),
    );
  }
}
