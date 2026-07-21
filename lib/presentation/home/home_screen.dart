import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/widget_sync_service.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/pro_launch_config.dart';
import '../../core/providers/purchases_provider.dart';
import '../../core/utils/share_card_renderer.dart';
import '../../data/models/quiz_session.dart';
import '../../data/models/daily_content.dart';
import '../../data/models/quote.dart';
import '../../data/models/thinker_quote.dart';
import '../../domain/providers/daily_content_provider.dart';
import '../../domain/providers/app_mode_provider.dart';
import '../../domain/providers/streak_provider.dart';
import '../../domain/providers/supabase_auth_provider.dart';
import '../../domain/providers/user_profile_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/adaptive_quote_text.dart';
import '../../widgets/quote_card.dart';
import '../loading/app_loading_screen.dart';
import '../shared/icon_circle.dart';
import '../shared/app_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({this.showBottomNavigationBar = true, super.key});

  final bool showBottomNavigationBar;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  ProviderSubscription<AsyncValue<DailyContent>>? _dailyContentSubscription;
  ProviderSubscription<AsyncValue<int>>? _streakSubscription;
  ProviderSubscription<AppMode>? _appModeSubscription;
  String? _lastWidgetSyncSignature;
  bool _widgetSyncInFlight = false;
  bool _widgetSyncNeedsRetry = false;

  /// What the last Supabase profile sync wrote, so repeat emissions of the same
  /// day for the same user do not re-issue an identical cloud write.
  String? _lastSyncedQuoteDate;
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _dailyContentSubscription = ref.listenManual<AsyncValue<DailyContent>>(
      dailyContentProvider,
      (_, asyncContent) {
        // Sync to home widget
        _syncHomeWidgetIfReady();

        // Sync daily quote date to Supabase if user is logged in
        _syncDailyQuoteDateToSupabase(asyncContent);
      },
    );
    _streakSubscription = ref.listenManual<AsyncValue<int>>(
      currentStreakProvider,
      (_, __) => _syncHomeWidgetIfReady(),
    );
    _appModeSubscription = ref.listenManual<AppMode>(
      appModeNotifierProvider,
      (_, __) => _syncHomeWidgetIfReady(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(streakControllerProvider.notifier).logTodayAndRefresh();
        _syncHomeWidgetIfReady();
      }
    });
  }

  @override
  void dispose() {
    _dailyContentSubscription?.close();
    _streakSubscription?.close();
    _appModeSubscription?.close();
    _controller.dispose();
    super.dispose();
  }

  String _dailyContentSignature(DailyContent content) {
    return content.when(
      quote: (quote) => 'quote:${quote.id}',
      thinkerQuote: (quote) => 'thinker:${quote.id}',
    );
  }

  void _syncHomeWidgetIfReady() {
    if (_widgetSyncInFlight) {
      _widgetSyncNeedsRetry = true;
      return;
    }

    final dailyContent = ref.read(dailyContentProvider).valueOrNull;
    final streak = ref.read(currentStreakProvider).valueOrNull;
    if (dailyContent == null || streak == null) {
      return;
    }

    final modeLabel = ref.read(appModeNotifierProvider).name.toUpperCase();
    final signature =
        '${_dailyContentSignature(dailyContent)}|$streak|$modeLabel';

    if (signature == _lastWidgetSyncSignature) {
      return;
    }

    _widgetSyncInFlight = true;
    unawaited(
      _performWidgetSync(
        content: dailyContent,
        streak: streak,
        modeLabel: modeLabel,
        signature: signature,
      ),
    );
  }

  Future<void> _performWidgetSync({
    required DailyContent content,
    required int streak,
    required String modeLabel,
    required String signature,
  }) async {
    try {
      await WidgetSyncService.syncDailyContent(
        content: content,
        streakCount: streak,
        modeLabel: modeLabel,
      );
      _lastWidgetSyncSignature = signature;
    } catch (e, st) {
      debugPrint('[Home] Widget sync failed: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _widgetSyncInFlight = false;
      if (mounted) {
        if (_widgetSyncNeedsRetry) {
          _widgetSyncNeedsRetry = false;
          Future.microtask(_syncHomeWidgetIfReady);
        }
      }
    }
  }

  void _syncDailyQuoteDateToSupabase(AsyncValue<DailyContent> asyncContent) {
    final content = asyncContent.valueOrNull;
    if (content == null) {
      return;
    }

    // Only sync if user is authenticated
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    // Get today's date in ISO format
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // This runs on every emission of dailyContentProvider — including each
    // pull-to-refresh and every retry — and the payload is identical each time.
    // One write per user per day is all the cloud profile needs.
    if (_lastSyncedQuoteDate == todayStr && _lastSyncedUserId == userId) {
      return;
    }
    _lastSyncedQuoteDate = todayStr;
    _lastSyncedUserId = userId;

    unawaited(
      Future(() async {
        try {
          final supabase = SupabaseSyncService();
          final userProfile = ref.read(userProfileProvider);

          // Sync the daily quote date to Supabase user profile
          await supabase.syncUserProfileToCloud(
            userId: userId,
            historicalInterests: userProfile.historicalInterests,
            politicalLeaning: userProfile.politicalLeaning.name,
            dailyQuoteDate: todayStr,
          );

          debugPrint('[Home] Daily quote date synced to Supabase: $todayStr');
        } catch (e, st) {
          debugPrint('[Home] Failed to sync daily quote date: $e');
          debugPrintStack(stackTrace: st);
        }
      }),
    );
  }

  /// Awaits the re-resolution rather than returning immediately, so the refresh
  /// indicator stays up until there is actually something new to show.
  ///
  /// Both providers are invalidated: the carousel is fed by
  /// `premiumDailyQuotesProvider`, so refreshing only `dailyContentProvider`
  /// left the visible content untouched. Today's pick itself is cached per day
  /// by design and will usually come back identical — the value here is
  /// recovering from a transient error, not shuffling the quote.
  Future<void> _refresh() async {
    ref.invalidate(dailyContentProvider);
    ref.invalidate(premiumDailyQuotesProvider);
    await Future.wait<void>(<Future<void>>[
      ref.read(dailyContentProvider.future).then((_) {}).catchError((_) {}),
      ref.read(premiumDailyQuotesProvider.future).then((_) {}).catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dailyContent = ref.watch(dailyContentProvider);
    final isPro = ref.watch(isProProvider);
    final premiumQuotesAsync = isPro
        ? ref.watch(premiumDailyQuotesProvider)
        : const AsyncValue<List<Quote>>.data(<Quote>[]);

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        bottomNavigationBar: widget.showBottomNavigationBar
            ? const AppNavigationBar(selectedIndex: 0)
            : null,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: <Widget>[
              EditorialSectionTitle(
                label: 'HEUTE',
                title: 'HEUTE',
                subtitle:
                    'Deine tägliche Ausgabe aus Zitaten und historischen Fakten.',
                trailing: Text(
                  _mastheadSubtitle(),
                  style: AppTheme.mastHeadSubtitle.copyWith(
                    color: AppColors.inkLight,
                  ),
                ),
              ),

              // ── Daily content ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingBase,
                  AppTheme.spacingBase,
                  AppTheme.spacingBase,
                  AppTheme.spacingXl,
                ),
                child: dailyContent.when(
                  data: (content) {
                    return FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: content.when(
                          quote: (quote) {
                            final fallbackCard = QuoteCard(
                              quote: quote,
                              onShare: () => ShareCardRenderer().shareQuote(quote),
                              onTap: () =>
                                  _showQuoteInsightSheet(context, quote),
                              onLongPress: () =>
                                  _showQuoteInsightSheet(context, quote),
                            );

                            if (!isPro) {
                              return fallbackCard;
                            }

                            return premiumQuotesAsync.when(
                              data: (quotes) {
                                final visibleQuotes = quotes.isEmpty
                                    ? <Quote>[quote]
                                    : quotes;
                                return _MainQuoteScroller(
                                  quotes: visibleQuotes,
                                  onQuoteTap: (Quote selectedQuote) =>
                                      _showQuoteInsightSheet(
                                        context,
                                        selectedQuote,
                                      ),
                                );
                              },
                              loading: () => fallbackCard,
                              error: (_, __) => fallbackCard,
                            );
                          },
                          thinkerQuote: (ThinkerQuote quote) =>
                              _ThinkerQuoteCard(quote: quote),
                        ),
                      ),
                    );
                  },
                  loading: () => const AppInlineLoadingState(
                    title: 'Tagesinhalt wird geladen',
                    subtitle: 'Home, Details und Widget werden vorbereitet ...',
                  ),
                  error: (error, _) => AppInlineErrorState(
                    title: 'Ladevorgang fehlgeschlagen',
                    message: 'Fehler: $error',
                    onRetry: () => ref.invalidate(dailyContentProvider),
                  ),
                ),
              ),

              // ── Entdecken (Denkeratlas, Quiz) ────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingBase,
                  0,
                  AppTheme.spacingBase,
                  AppTheme.spacingXl,
                ),
                child: const _ExploreSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ENTDECKEN',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          _ExploreLinkRow(
            label: 'DENKERATLAS',
            description: 'Alle Denker und Zitate durchstöbern',
            isProFeature: kProLaunchEnabled,
            onTap: () => context.push('/thinkers'),
          ),
          Container(height: 1, color: scheme.outline),
          _ExploreLinkRow(
            label: 'ZITAT-QUIZ',
            // Interpolated, not spelled out: a run can legitimately come up
            // short on a heavily filtered pool, and the quiz screen already
            // reports the real count.
            description:
                'Erkennst du die Quelle? Bis zu $kQuizQuestionCount Fragen '
                'täglich',
            isProFeature: false,
            onTap: () => context.push('/quiz'),
          ),
        ],
      ),
    );
  }
}

class _ExploreLinkRow extends StatelessWidget {
  const _ExploreLinkRow({
    required this.label,
    required this.description,
    required this.isProFeature,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isProFeature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        label,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (isProFeature) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          color: AppColors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.redOnRed,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// Home hero/tip card removed per scope-reduction request.

class _ThinkerQuoteCard extends StatelessWidget {
  const _ThinkerQuoteCard({required this.quote});

  final ThinkerQuote quote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.rule, width: 1),
                ),
                child: IconCircle(
                  icon: Icons.person_outline,
                  background: AppColors.paperDark,
                  iconColor: AppColors.red,
                  size: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      quote.author.toUpperCase(),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${quote.source} · ${quote.year}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdaptiveQuoteText(
            text: quote.textDe,
            minFontSize: 22,
            maxFontSize: 30,
            maxLines: 7,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Container(width: 28, height: 2, color: AppColors.red),
        ],
      ),
    );
  }
}

class _MainQuoteScroller extends StatefulWidget {
  const _MainQuoteScroller({required this.quotes, required this.onQuoteTap});

  final List<Quote> quotes;
  final ValueChanged<Quote> onQuoteTap;

  @override
  State<_MainQuoteScroller> createState() => _MainQuoteScrollerState();
}

class _MainQuoteScrollerState extends State<_MainQuoteScroller> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSwipeHint = false;
            });
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(_MainQuoteScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The feed can shrink under a page the user is already on — narrowing the
    // political lens or the interests re-resolves it to fewer quotes. The State
    // (and its controller) survives that rebuild, so without this the PageView
    // kept an out-of-range page: an empty viewport and no highlighted dot until
    // the user scrolled back by hand.
    if (widget.quotes.length != oldWidget.quotes.length &&
        _currentPage >= widget.quotes.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A single quote never needs the carousel chrome (hint, fixed height,
    // dots) — render it exactly like the free daily card.
    if (widget.quotes.length <= 1) {
      final quote = widget.quotes.first;
      return QuoteCard(
        quote: quote,
        onShare: () => ShareCardRenderer().shareQuote(quote),
        onTap: () => widget.onQuoteTap(quote),
        onLongPress: () => widget.onQuoteTap(quote),
      );
    }

    final media = MediaQuery.sizeOf(context);
    final pageHeight = (media.height * 0.72).clamp(420.0, 600.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.quotes.length > 1)
          AnimatedOpacity(
            opacity: _showSwipeHint ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return Transform.translate(
                    offset: Offset(value * 8, 0),
                    child: child,
                  );
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.swipe_rounded,
                      size: 16,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Wische nach links/rechts für weitere Zitate',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemCount: widget.quotes.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (BuildContext context, int index) {
              final quote = widget.quotes[index];
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: QuoteCard(
                  quote: quote,
                  onShare: () => ShareCardRenderer().shareQuote(quote),
                  onTap: () => widget.onQuoteTap(quote),
                  onLongPress: () => widget.onQuoteTap(quote),
                ),
              );
            },
          ),
        ),
        if (widget.quotes.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(widget.quotes.length, (index) {
                final active = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.red : AppColors.rule,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
      ],
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
        color: scheme.surface,
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
                color: scheme.onSurface,
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

extension on _HomeScreenState {
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
                            ShareCardRenderer().shareQuote(quote);
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
}

String _mastheadSubtitle() {
  final now = DateTime.now();
  final monthNames = <String>[
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  final issueNumber = now.difference(DateTime(2000, 1, 1)).inDays;
  return '${now.day}. ${monthNames[now.month - 1]} ${now.year} · Ausgabe $issueNumber';
}
