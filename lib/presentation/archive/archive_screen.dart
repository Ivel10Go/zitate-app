// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/providers/archive_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/compact_quote_card.dart';
import '../home/widgets/fact_block.dart';
import '../loading/app_loading_screen.dart';
import 'widgets/archive_filter_chips.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  bool _filtersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final archiveAsync = ref.watch(archiveProvider);
    final scheme = Theme.of(context).colorScheme;
    final selectedTheme = ref.watch(archiveThemeFilterProvider);
    final selectedOrientation = ref.watch(archiveOrientationFilterProvider);
    final query = ref.watch(archiveQueryProvider);

    void setTab(ArchiveTab tab) {
      ref.read(archiveTabProvider.notifier).state = tab;
      ref.read(archiveThemeFilterProvider.notifier).state = null;
      ref.read(archiveOrientationFilterProvider.notifier).state = null;
      setState(() {
        _filtersExpanded = false;
      });
    }

    void clearFilters() {
      ref.read(archiveThemeFilterProvider.notifier).state = null;
      ref.read(archiveOrientationFilterProvider.notifier).state = null;
    }

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        bottomNavigationBar: const AppNavigationBar(selectedIndex: 1),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  bottom: BorderSide(color: scheme.outline, width: 1),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLarge,
                AppTheme.spacingBase,
                AppTheme.spacingLarge,
                AppTheme.spacingBase,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: archiveAsync.when(
                          data: (_) => Text('ARCHIV', style: AppTheme.masthead),
                          loading: () =>
                              Text('ARCHIV', style: AppTheme.masthead),
                          error: (_, __) =>
                              Text('ARCHIV', style: AppTheme.masthead),
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingMedium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          archiveAsync.when(
                            data: (items) => Text(
                              '${items.length} Einträge',
                              style: AppTheme.mastHeadSubtitle,
                            ),
                            loading: () => Text(
                              '— Einträge',
                              style: AppTheme.mastHeadSubtitle,
                            ),
                            error: (_, __) => Text(
                              '— Einträge',
                              style: AppTheme.mastHeadSubtitle,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXs),
                          Container(width: 32, height: 2, color: AppColors.red),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Suche, filtere und springe zwischen Themen, Interessen und Geschichte.',
                    style: AppTheme.bodyMedium.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),

                  const SizedBox(height: AppTheme.spacingMedium),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'SUCHE',
                      hintText: 'Begriffe, Personen, Quellen',
                      labelStyle: AppTheme.labelLarge.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(Icons.search, color: scheme.onSurface),
                      suffixIcon: query.trim().isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                ref.read(archiveQueryProvider.notifier).state =
                                    '';
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Suche löschen',
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTheme.bodyMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                    onChanged: (value) {
                      ref.read(archiveQueryProvider.notifier).state = value;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          selectedTheme == null && selectedOrientation == null
                              ? 'Filter einklappen, wenn du nur stöbern willst.'
                              : [
                                  if (selectedTheme != null)
                                    'Thema: $selectedTheme',
                                  if (selectedOrientation != null)
                                    'Orientierung: $selectedOrientation',
                                ].join(' · '),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _filtersExpanded = !_filtersExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSmall,
                            vertical: AppTheme.spacingSmall,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          side: const BorderSide(
                            color: AppColors.ink,
                            width: 1,
                          ),
                        ),
                        icon: Icon(
                          _filtersExpanded ? Icons.expand_less : Icons.tune,
                          size: 16,
                        ),
                        label: Text(
                          _filtersExpanded ? 'FILTER SCHLIESSEN' : 'FILTER',
                          style: AppTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  if (_filtersExpanded) ...<Widget>[
                    const SizedBox(height: AppTheme.spacingSmall),
                    ArchiveFilterChips(
                      onClearFilters:
                          selectedTheme == null && selectedOrientation == null
                          ? null
                          : clearFilters,
                    ),
                  ] else if (selectedTheme != null ||
                      selectedOrientation != null) ...<Widget>[
                    const SizedBox(height: AppTheme.spacingSmall),
                    TextButton.icon(
                      onPressed: clearFilters,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSmall,
                          vertical: AppTheme.spacingSmall,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        side: const BorderSide(color: AppColors.ink, width: 1),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text('FILTER LÖSCHEN', style: AppTheme.labelSmall),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: archiveAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _ArchiveEmptyStateCard(
                      title: 'Keine Treffer',
                      body:
                          'Probiere eine andere Suche oder entferne einzelne Filter, um wieder mehr Einträge zu sehen.',
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      AppTheme.spacingBase,
                      AppTheme.spacingLarge,
                      AppTheme.spacingXl,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingMedium,
                        ),
                        child: item.isQuote
                            ? CompactQuoteCard(
                                quote: item.quote!,
                                onTap: () => context.push(
                                  '/detail/${Uri.encodeComponent(item.quote!.id)}',
                                ),
                              )
                            : FactBlock(
                                fact: item.fact!,
                                onRelatedQuoteTap:
                                    item.fact!.relatedQuoteIds.isNotEmpty
                                    ? () => context.push(
                                        '/detail/${Uri.encodeComponent(item.fact!.relatedQuoteIds.first)}',
                                      )
                                    : null,
                              ),
                      );
                    },
                  );
                },
                loading: () => const AppInlineLoadingState(
                  title: 'Archiv wird geladen',
                  subtitle: 'Einträge und Filter werden vorbereitet ...',
                ),
                error: (error, _) => AppInlineErrorState(
                  title: 'Archiv konnte nicht geladen werden',
                  message: 'Fehler: $error',
                  onRetry: () => ref.invalidate(archiveProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Archive intro/tip card removed per scope-reduction request.

class _ArchiveEmptyStateCard extends StatelessWidget {
  const _ArchiveEmptyStateCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingLarge,
          AppTheme.spacingSmall,
          AppTheme.spacingLarge,
          AppTheme.spacingXl,
        ),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outline, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 34, height: 2, color: AppColors.red),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                body,
                style: AppTheme.bodyMedium.copyWith(
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

class _ArchiveTabButton extends StatelessWidget {
  const _ArchiveTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSmall,
          horizontal: AppTheme.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : scheme.surface,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.paper : AppColors.inkMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
