import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_loader.dart';
import '../../data/models/thinker_quote.dart';
import '../../domain/providers/thinkers_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../shared/app_card.dart';
import '../loading/app_loading_screen.dart';

class ThinkersScreen extends ConsumerWidget {
  const ThinkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(thinkerTypeProvider);
    final selectedAuthor = ref.watch(selectedAuthorProvider);
    final searchQuery = ref.watch(thinkerSearchQueryProvider);
    final isSearching = searchQuery.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return AndroidBackGuard(
      onBlockedPop: () {
        if (isSearching) {
          ref.read(thinkerSearchQueryProvider.notifier).state = '';
          return true;
        }

        if (selectedAuthor != null) {
          ref.read(selectedAuthorProvider.notifier).state = null;
          return true;
        }

        return false;
      },
      child: AppDecoratedScaffold(
        appBar: null,
        child: Column(
          children: <Widget>[
            // Masthead
            AppCard(
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
                    'DENKERATLAS',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(width: 40, height: 2, color: scheme.primary),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) =>
                        ref.read(thinkerSearchQueryProvider.notifier).state =
                            value,
                    decoration: InputDecoration(
                      labelText: 'SUCHE',
                      hintText: 'Zitat, Autor, Qülle, Jahr',
                      prefixIcon: Icon(Icons.search, color: scheme.onSurface),
                      suffixIcon: searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                ref
                                        .read(
                                          thinkerSearchQueryProvider.notifier,
                                        )
                                        .state =
                                    '';
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Suche löschen',
                            ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (!isSearching) ...<Widget>[
                    const SizedBox(height: 12),
                    // Type toggle
                    Row(
                      children: <Widget>[
                        _TypeTabButton(
                          label: 'PHILOSOPHEN',
                          active: selectedType == ThinkerType.philosopher,
                          onTap: () {
                            ref.read(thinkerTypeProvider.notifier).state =
                                ThinkerType.philosopher;
                            ref.read(selectedAuthorProvider.notifier).state =
                                null;
                          },
                        ),
                        const SizedBox(width: 20),
                        _TypeTabButton(
                          label: 'POLITIKER',
                          active: selectedType == ThinkerType.politician,
                          onTap: () {
                            ref.read(thinkerTypeProvider.notifier).state =
                                ThinkerType.politician;
                            ref.read(selectedAuthorProvider.notifier).state =
                                null;
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLarge,
                0,
                AppTheme.spacingLarge,
                0,
              ),
              child: SizedBox.shrink(),
            ),
            Expanded(
              child: isSearching
                  ? _SearchQuoteList()
                  : selectedAuthor == null
                  ? _AuthorList(type: selectedType)
                  : _QuoteList(author: selectedAuthor),
            ),
          ],
        ),
      ),
    );
  }
}

// Thinkers intro/tip card removed per scope-reduction request.

class _TypeTabButton extends StatelessWidget {
  const _TypeTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 1.0,
                color: active ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 56,
              height: 2,
              color: active ? AppColors.red : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorList extends ConsumerWidget {
  const _AuthorList({required this.type});

  final ThinkerType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorsAsync = ref.watch(thinkerAuthorsProvider);

    return authorsAsync.when(
      data: (authors) {
        if (authors.isEmpty) {
          return Center(
            child: Text(
              'Keine Einträge gefunden.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingLarge,
            AppTheme.spacingLarge,
            AppTheme.spacingLarge,
            AppTheme.spacingXl,
          ),
          itemCount: authors.length,
          separatorBuilder: (_, __) =>
              Container(height: 1, color: AppColors.rule),
          itemBuilder: (context, index) {
            final author = authors[index];
            return InkWell(
              onTap: () {
                ref.read(selectedAuthorProvider.notifier).state = author;
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            author,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type == ThinkerType.philosopher
                                ? 'Philosoph'
                                : 'Politiker',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.inkMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const AppInlineLoadingState(
        title: 'Denker werden geladen',
        subtitle: 'Autorenliste wird vorbereitet ...',
      ),
      error: (error, _) => AppInlineErrorState(
        title: 'Denker konnten nicht geladen werden',
        message: 'Fehler: $error',
        onRetry: () => ref.invalidate(thinkerAuthorsProvider),
      ),
    );
  }
}

class _QuoteList extends ConsumerWidget {
  const _QuoteList({required this.author});

  final String author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(thinkerQuotesProvider);

    return Column(
      children: <Widget>[
        // Back bar
        Container(
          color: AppColors.paperDark,
          child: InkWell(
            onTap: () => ref.read(selectedAuthorProvider.notifier).state = null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingMedium,
                10,
                AppTheme.spacingLarge,
                10,
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'ZURÜCK',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    author.toUpperCase(),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: quotesAsync.when(
            data: (quotes) {
              if (quotes.isEmpty) {
                return const Center(child: Text('Keine Zitate gefunden.'));
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingLarge,
                  AppTheme.spacingBase,
                  AppTheme.spacingLarge,
                  AppTheme.spacingXl,
                ),
                itemCount: quotes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ThinkerQuoteCard(quote: quotes[index]),
                  );
                },
              );
            },
            loading: () => const AppInlineLoadingState(
              title: 'Zitate werden geladen',
              subtitle: 'Einträge des Archivs werden zusammengestellt ...',
            ),
            error: (error, _) => AppInlineErrorState(
              title: 'Zitate konnten nicht geladen werden',
              message: 'Fehler: $error',
              onRetry: () => ref.invalidate(thinkerQuotesProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchQuoteList extends ConsumerWidget {
  const _SearchQuoteList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(thinkerSearchQueryProvider).trim();
    final quotesAsync = ref.watch(thinkerSearchQuotesProvider);

    return quotesAsync.when(
      data: (quotes) {
        if (quotes.isEmpty) {
          return Center(
            child: Text(
              'Keine Treffer für "$searchQuery".',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingLarge,
            AppTheme.spacingBase,
            AppTheme.spacingLarge,
            AppTheme.spacingXl,
          ),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingBase),
              child: _ThinkerQuoteCard(quote: quotes[index]),
            );
          },
        );
      },
      loading: () => const AppInlineLoadingState(
        title: 'Suchergebnisse werden geladen',
        subtitle: 'Passende Zitate werden zusammengestellt ...',
      ),
      error: (error, _) => AppInlineErrorState(
        title: 'Suchergebnisse konnten nicht geladen werden',
        message: 'Fehler: $error',
        onRetry: () => ref.invalidate(thinkerSearchQuotesProvider),
      ),
    );
  }
}

class _ThinkerQuoteCard extends StatelessWidget {
  const _ThinkerQuoteCard({required this.quote});

  final ThinkerQuote quote;

  @override
  Widget build(BuildContext context) {
    final yearLabel = quote.year < 0
        ? '${quote.year.abs()} v. Chr.'
        : '${quote.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Kicker
        Container(
          color: AppColors.red,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                quote.author.toUpperCase(),
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redOnRed,
                  letterSpacing: 1.8,
                ),
              ),
              Text(
                yearLabel,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 8,
                  color: AppColors.redOnRed.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Card body
        Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              left: BorderSide(color: AppColors.ink, width: 1),
              right: BorderSide(color: AppColors.ink, width: 1),
              bottom: BorderSide(color: AppColors.ink, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Featured image (if available)
              if (quote.imageUrl != null && quote.imageUrl!.isNotEmpty)
                CachedImageLoader(
                  imageUrl: quote.imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  cacheConfig: const ImageCacheConfig(),
                ),
              // Quote content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '»${quote.textDe}«',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(width: 24, height: 2, color: AppColors.red),
                    const SizedBox(height: 8),
                    Text(
                      '— ${quote.author}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
