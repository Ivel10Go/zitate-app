
# CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project identity

Flutter app for daily quotes ("Zitate-App" / marketing name "Quotidian"). A "history facts" feature existed until schema v7 and was removed entirely (asset, `HistoryFactEntries` table, DAO, repository, providers, `FactBlock` UI, `HomeContentMode` setting) — do not reintroduce it. Note the naming split across the repo — be aware of it when searching, don't assume one name:
- pubspec package name: `zitate_app`
- Android/iOS bundle id: `com.quotidian.app`
- Root `MaterialApp` widget: `DasKapitalApp` (`lib/app.dart`), title `"Quotidian"`
- Repo/folder name: `marx_app`

## Commands

```bash
flutter pub get                 # install dependencies
flutter analyze                 # static analysis (flutter_lints via analysis_options.yaml)
flutter run                     # run on connected device/emulator
flutter build appbundle         # release Android App Bundle
flutter test                    # run the whole suite
flutter test test/quiz_builder_test.dart              # one file
flutter test --plain-name "a run never repeats a quote"  # one test by name
```

`test/` holds two suites, both of which load the real `assets/thinkers_quotes.json` rather than fixtures — so they double as guards on the content asset:
- `quote_database_integrity_test.dart` — asserts the asset against the defects that forced the July 2026 rebuild (template explanations, `ue`/`oe`/`ae` corruption, duplicate texts/ids). Run it after **any** edit to the quote asset.
- `quiz_builder_test.dart` — exercises `QuizBuilder` against the shipped pool, so a change to the asset's difficulty labels or author spread can fail it legitimately.

There is no widget or integration test coverage; most of `lib/` is untested.

After changing any Drift table (`lib/data/database/tables.dart`) or DAO, regenerate the generated database code:
```bash
dart run build_runner build --delete-conflicting-outputs
```
(`app_database.g.dart` is generated output — never hand-edit it.)

Useful one-off scripts (PowerShell, in `scripts/`):
- `release_build_for_upload.ps1` — pub get → analyze → build appbundle → verify the AAB exists, used before a Play Store upload.
- `widget_debug.ps1` — adb-based helper to debug the Android home-screen widget (launches the app, dumps filtered logcat and `HomeWidgetPreferences.xml`, attempts an APPWIDGET_UPDATE broadcast).

There is no CI pipeline (no `.github/workflows`).

`tools/` and `process_quotes.py` are one-off/offline Python scripts that were used on the quote datasets. **Do not run them against `assets/thinkers_quotes.json`.** They caused the two defects the current database was rebuilt to remove: `enrich_explanations_ai.py` (in its `--api local` mode) generated template explanations with the author's name swapped in, which say nothing; and `normalize_umlauts.py` rewrote `ue`/`oe`/`ae` inside non-German words, corrupting titles and names ("Virtue" → "Virtü", "Poems" → "Pöms", "Goethe" → "Göthe"). `data_backup/` holds the superseded datasets — it is outside `assets/` on purpose so it does not ship in the bundle.

`.env` (gitignored, see `.env.example`) supplies `SUPABASE_URL` / `SUPABASE_ANON_KEY` for local runs; release builds prefer `--dart-define` build-time values over `.env` (see `lib/main.dart`).

## Architecture

### Layering

`lib/` follows a data → domain → presentation split:
- `data/` — Drift (SQLite) database (`data/database/`), repositories (`data/repositories/`), and plain model classes (`data/models/`). Repositories are the only layer that talks to `AppDatabase`/DAOs directly.
- `domain/` — Riverpod providers (`domain/providers/`) and services (`domain/services/`) that mediate between repositories and UI. Providers here compose repositories, settings, and resolvers; screens should watch these, not repositories directly.
- `presentation/` — screens grouped by feature (`home/`, `quiz/`, `archive/`, `onboarding/`, `settings/`, `paywall/`, `admin/`, etc.), each with local `widgets/` subfolders for screen-specific components.
- `widgets/` (top-level) and `presentation/shared/` — cross-screen reusable widgets (`AppDecoratedScaffold`, `EditorialSectionTitle`, `AppCard`, `IconCircle`, `QuoteCard`, navigation bar, etc.). Prefer these over ad-hoc screen-local styling when a screen needs to match the rest of the app.
- `core/` — cross-cutting concerns: `core/theme` (design system), `core/router` (go_router config), `core/bootstrap` (startup sequencing), `core/services` (notifications, purchases, Supabase sync/auth, crash reporting, widget sync, TTS, etc.), `core/providers`, `core/utils`, `core/constants`.

Two provider directories exist and are *not* interchangeable — check both before assuming a provider is missing or duplicated. `core/providers/` holds the infrastructure-facing ones (`purchases_provider.dart` with `isProProvider`, `supabase_auth_provider.dart`, `test_auth_provider.dart`); `domain/providers/` holds the feature ones, including same-named files (`purchases_provider.dart` there only wires RevenueCat login/logout to auth state; `supabase_auth_provider.dart` there exposes `currentSupabaseUserProvider`).

State management is Riverpod (`flutter_riverpod`) throughout — no other state management library is used. Routing is `go_router`, configured in `core/router/app_router.dart` with a `StatefulShellRoute.indexedStack` for the three bottom-nav tabs (home `/`, `/favorites`, `/settings`) wrapped in `HomeFavoritesShell`; other screens (`/detail/:id`, `/onboarding`, `/auth`, `/admin`, etc.) are plain top-level `GoRoute`s outside the shell.

### Startup sequence

Startup is intentionally split into three stages to keep perceived launch time low — understand this before touching bootstrap/provider init order:
1. `main()` (`lib/main.dart`) does binding init, crash reporting, orientation lock, dotenv/Supabase init (all time-boxed with timeouts, failures are non-fatal), then runs `_BootstrapGateApp` — a plain (non-Riverpod) widget that drives `AppBootstrap.initialize()` outside of any `ProviderScope`.
2. `AppBootstrap` (`core/bootstrap/app_bootstrap.dart`) does the minimum needed to pick the correct `initialRoute` (auth/onboarding/guest/home) from `SharedPreferences` and emits progress via a broadcast stream consumed by `AppLoadingScreen`. It deliberately does **not** touch the database or return real daily content (`dailyContent: null` in `AppBootstrapResult`) — DB seeding must happen inside the `ProviderScope` so it shares the single `AppDatabase` instance from `appDatabaseProvider`. It schedules a `_scheduleDeferredOperations()` (widget refresh, notification scheduling) 500ms after returning.
3. Once bootstrap resolves, `main.dart` mounts `ProviderScope` + `DasKapitalApp`, overriding `initialRouteProvider` with the resolved route. From here Riverpod providers take over: `initialSeedProvider` (idempotent, guarded by an `app_seeded_vN` SharedPreferences flag — bump the suffix whenever the seed asset changes) seeds the Drift DB from `assets/thinkers_quotes.json` before `dailyContentProvider` or other repository-backed providers resolve. Seeding upserts and then calls `QuoteDao.pruneQuotesNotIn`, so quotes deleted from the asset also disappear from already-seeded installs.

### Daily content resolution & caching

`dailyContentProvider` (`domain/providers/daily_content_provider.dart`) is the single source of truth for "today's" quote shown on Home. It:
- Reads a per-user, per-day cache from `SharedPreferences` first (`_readCachedDailyContent`, keyed by user id + date) and returns immediately if present — avoids recomputation on every provider rebuild within the same day.
- Otherwise waits on `initialSeedProvider.future`, then calls `DailyContentResolver.resolveDailyContentFromRepository` (`domain/services/daily_content_resolver.dart`), which factors in `AppMode` (public vs. admin) and user profile personalization.
- Falls back to the first quote from the repository if resolution fails or returns nothing, so Home always has something to render.
- Caches the resolved content afterward. Any change to caching keys/serialization must stay in sync with `_serializeDailyContent`/`_deserializeDailyContent`.

`premiumDailyQuotesProvider` layers a personalized multi-quote feed on top for Pro users (capped at `kDailyFeedQuoteCount`, a fixed number rather than one-per-interest — many interests produced an overloaded feed that also burned through the collection too fast); Home falls back to the single daily quote if this errors or is loading. `QuoteRotationStore` (`domain/services/quote_rotation_store.dart`) persists recently-surfaced feed IDs in `SharedPreferences` so the resolver can avoid repeats for several weeks; it is best-effort and degrades to "no history" on any failure.

### Pro soft-launch kill switch

`kProLaunchEnabled` in `core/constants/pro_launch_config.dart` is currently `false`, which means **the app ships fully free**: `isProProvider` (`core/providers/purchases_provider.dart`) returns `true` for every user, and every Pro badge and paywall entry point in Settings/Account/Home is compiled out via `if (kProLaunchEnabled)`. The whole RevenueCat integration, paywall screen, and gating logic stay intact behind it — flipping the flag to `true` re-enables paid Pro without rebuilding anything. So: when a Pro-gated feature (Denkeratlas, quiz without daily limit, personalized feed, PDF export) appears ungated at runtime, that is this flag, not a bug; and any new Pro-gated UI must respect the same flag or it will leak paywall hints into the free launch.

### Quiz

`QuizBuilder` (`domain/services/quiz_builder.dart`) is deliberately free of Riverpod and the database so its selection rules can be tested directly against the seed asset — keep it that way, and put any I/O in `quiz_provider.dart` instead. Non-obvious rules encoded there, all of them driven by properties of the actual quote pool (~200 authors over ~300 quotes, so most authors appear exactly once):
- The asset uses two difficulty vocabularies (`easy`/`medium`/`hard` and `beginner`/`intermediate`/`advanced`); `_difficultyAliases` maps them onto three buckets. Without it ~80 quotes fall out of every bucket.
- Questions are drawn 4/4/2 across the buckets and sorted easiest-first — a run ramps up, it is never shuffled.
- Distractor authors are picked *further* away for easy questions and *closer* (contemporaries, shared themes) only for advanced ones. If the pool holds too few other authors, a question shows fewer options rather than padding or looping.
- `quiz_provider.dart` feeds it two lists: `candidates` (distinct quotes) and `drawPool` (the same quotes weight-expanded by `PersonalizationService.getWeightedQuotes`, one entry per unit of weight). Anything reading `drawPool` must de-duplicate.

### Quote database — content rules

`assets/thinkers_quotes.json` is the only content asset the app ships. It was rebuilt from scratch in July 2026 because roughly half the previous 539 entries were fabricated: LLM-written summary sentences attributed to real people as if they were quotations (Adam Smith, Angela Davis, Mandela, Foucault, and whole padded work-series such as `manifest_009`–`012`), plus ~140 entries whose "explanation" was one template with the name swapped in. Two rules follow, and they are not negotiable:

1. **Every `text_de` must be a real, verbatim utterance of a real person.** Not a paraphrase, not a summary of their position, not a plausible-sounding sentence in their style. If a quote cannot be tied to a work, speech, letter or documented occasion, it does not go in. Where a famous line is popularly misattributed or has no clean source (Gandhi's "an eye for an eye", Wilde's "be yourself", the Rumi and Hawking lines), the entry says so openly in `source` and `explanation_long` rather than pretending.
2. **Every `explanation_short` / `explanation_long` must explain that specific quote** — its context, what it actually claims, why it matters, and where it is commonly misread. Never generate them from a template, and never let them describe the recommendation algorithm instead of the quote (the old data had explanations reading "strengthens neutral and centrist recommendations").

Adding quotes means writing them by hand. There is no script for this, and a script is exactly how the database got ruined.

`test/quote_database_integrity_test.dart` enforces what is mechanically checkable (template-explanation fingerprints, umlaut corruption, duplicate texts and ids). Rule 1 — authenticity — is *not* machine-checkable and the test says so explicitly: a fabricated quote is indistinguishable from a real one by any rule, so it remains a review obligation. A green test run is not evidence that a new quote is real.

### Design system

`core/theme/app_theme.dart` + `core/theme/app_colors.dart` define a print/editorial-styled design system (Playfair Display for display/quote text, IBM Plex Sans for UI chrome, sharp square corners — `BorderRadius.zero` everywhere, 1px hairline borders instead of elevation/shadows). `AppTheme.initializeTextStyles()` pre-builds every `TextStyle` once during bootstrap specifically to avoid runtime `GoogleFonts` fetches; both light and dark variants are built eagerly at that point, so any new text style must be added as a static field + init-time assignment + getter, mirrored for light and dark.

Shared layout primitives screens should reuse for consistency with Home (`presentation/home/home_screen.dart` is the reference implementation): `AppDecoratedScaffold` (scaffold + `SafeArea`, no elevation), `EditorialSectionTitle` (the "HEUTE"-style masthead header block), `AppCard` (bordered content card), `IconCircle`, `AppNavigationBar`, and the `AppInlineLoadingState` / `AppInlineErrorState` / `AppFullscreenRecoveryScreen` trio (`presentation/loading/app_loading_screen.dart`) for loading/error states — used consistently from `main.dart` down through individual providers' `.when(loading:, error:)` branches.

### Home-screen widget & background isolate

The Android home-screen widget (`home_widget`) is refreshed by a `workmanager` periodic task (`core/services/background_tasks_service.dart`). Its `workmanagerCallbackDispatcher` runs in a **separate background isolate** with no `ProviderScope`: it opens its own `AppDatabase()` (not the one from `appDatabaseProvider`), receives settings as primitives via `inputData` rather than reading providers, and deliberately avoids platform-channel plugins. Keep any code you add there self-contained the same way.

### Political mode duality

The app has a public mode and an "admin/Marx" mode (`AppMode.public` / `AppMode.adminMarx`, `domain/providers/app_mode_provider.dart`) gating content personalization and the `/admin` route (`adminAccessProvider` redirect guard in `app_router.dart`). Several providers thread `appMode` through alongside user profile/personalization — check how existing resolvers consume it before adding new personalized content paths.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
