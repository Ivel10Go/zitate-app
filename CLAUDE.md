
# CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project identity

Flutter app for daily quotes/history facts ("Zitate-App" / marketing name "Quotidian"). Note the naming split across the repo — be aware of it when searching, don't assume one name:
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
```

There is no `test/` directory and no automated test suite in this repo currently — do not assume `flutter test` has coverage to run.

After changing any Drift table (`lib/data/database/tables.dart`) or DAO, regenerate the generated database code:
```bash
dart run build_runner build --delete-conflicting-outputs
```
(`app_database.g.dart` is generated output — never hand-edit it.)

Useful one-off scripts (PowerShell, in `scripts/`):
- `release_build_for_upload.ps1` — pub get → analyze → build appbundle → verify the AAB exists, used before a Play Store upload.
- `widget_debug.ps1` — adb-based helper to debug the Android home-screen widget (launches the app, dumps filtered logcat and `HomeWidgetPreferences.xml`, attempts an APPWIDGET_UPDATE broadcast).

There is no CI pipeline (no `.github/workflows`).

`tools/` and `process_quotes.py` are one-off/offline Python scripts for curating and validating the quote/thinker content datasets (dedup, authenticity checks, umlaut/encoding fixes, Supabase import prep) — they operate on JSON/CSV data files, not on the Flutter app, and are not part of the app build.

`.env` (gitignored, see `.env.example`) supplies `SUPABASE_URL` / `SUPABASE_ANON_KEY` for local runs; release builds prefer `--dart-define` build-time values over `.env` (see `lib/main.dart`).

## Architecture

### Layering

`lib/` follows a data → domain → presentation split:
- `data/` — Drift (SQLite) database (`data/database/`), repositories (`data/repositories/`), and plain model classes (`data/models/`). Repositories are the only layer that talks to `AppDatabase`/DAOs directly.
- `domain/` — Riverpod providers (`domain/providers/`) and services (`domain/services/`) that mediate between repositories and UI. Providers here compose repositories, settings, and resolvers; screens should watch these, not repositories directly.
- `presentation/` — screens grouped by feature (`home/`, `quiz/`, `archive/`, `onboarding/`, `settings/`, `paywall/`, `admin/`, etc.), each with local `widgets/` subfolders for screen-specific components.
- `widgets/` (top-level) and `presentation/shared/` — cross-screen reusable widgets (`AppDecoratedScaffold`, `EditorialSectionTitle`, `AppCard`, `IconCircle`, `QuoteCard`, navigation bar, etc.). Prefer these over ad-hoc screen-local styling when a screen needs to match the rest of the app.
- `core/` — cross-cutting concerns: `core/theme` (design system), `core/router` (go_router config), `core/bootstrap` (startup sequencing), `core/services` (notifications, purchases, Supabase sync/auth, crash reporting, widget sync, TTS, etc.), `core/providers`, `core/utils`, `core/constants`.

State management is Riverpod (`flutter_riverpod`) throughout — no other state management library is used. Routing is `go_router`, configured in `core/router/app_router.dart` with a `StatefulShellRoute.indexedStack` for the three bottom-nav tabs (home `/`, `/favorites`, `/settings`) wrapped in `HomeFavoritesShell`; other screens (`/detail/:id`, `/onboarding`, `/auth`, `/admin`, etc.) are plain top-level `GoRoute`s outside the shell.

### Startup sequence

Startup is intentionally split into three stages to keep perceived launch time low — understand this before touching bootstrap/provider init order:
1. `main()` (`lib/main.dart`) does binding init, crash reporting, orientation lock, dotenv/Supabase init (all time-boxed with timeouts, failures are non-fatal), then runs `_BootstrapGateApp` — a plain (non-Riverpod) widget that drives `AppBootstrap.initialize()` outside of any `ProviderScope`.
2. `AppBootstrap` (`core/bootstrap/app_bootstrap.dart`) does the minimum needed to pick the correct `initialRoute` (auth/onboarding/guest/home) from `SharedPreferences` and emits progress via a broadcast stream consumed by `AppLoadingScreen`. It deliberately does **not** touch the database or return real daily content (`dailyContent: null` in `AppBootstrapResult`) — DB seeding must happen inside the `ProviderScope` so it shares the single `AppDatabase` instance from `appDatabaseProvider`. It schedules a `_scheduleDeferredOperations()` (widget refresh, notification scheduling) 500ms after returning.
3. Once bootstrap resolves, `main.dart` mounts `ProviderScope` + `DasKapitalApp`, overriding `initialRouteProvider` with the resolved route. From here Riverpod providers take over: `initialSeedProvider` (idempotent, guarded by a `app_seeded_v1` SharedPreferences flag) seeds the Drift DB from `assets/thinkers_quotes.json` before `dailyContentProvider` or other repository-backed providers resolve.

### Daily content resolution & caching

`dailyContentProvider` (`domain/providers/daily_content_provider.dart`) is the single source of truth for "today's" quote/fact/thinker-quote shown on Home. It:
- Reads a per-user, per-day cache from `SharedPreferences` first (`_readCachedDailyContent`, keyed by user id + date) and returns immediately if present — avoids recomputation on every provider rebuild within the same day.
- Otherwise waits on `initialSeedProvider.future`, then calls `DailyContentResolver.resolveDailyContentFromRepository` (`domain/services/daily_content_resolver.dart`), which factors in `AppMode` (public vs. admin), user profile personalization, and `HomeContentMode` settings.
- Falls back to the first quote/fact from the repository if resolution fails or returns nothing, so Home always has something to render.
- Caches the resolved content afterward. Any change to caching keys/serialization must stay in sync with `_serializeDailyContent`/`_deserializeDailyContent`.

`premiumDailyQuotesProvider` layers a personalized multi-quote feed on top for Pro users; Home falls back to the single daily quote if this errors or is loading.

### Design system

`core/theme/app_theme.dart` + `core/theme/app_colors.dart` define a print/editorial-styled design system (Playfair Display for display/quote text, IBM Plex Sans for UI chrome, sharp square corners — `BorderRadius.zero` everywhere, 1px hairline borders instead of elevation/shadows). `AppTheme.initializeTextStyles()` pre-builds every `TextStyle` once during bootstrap specifically to avoid runtime `GoogleFonts` fetches; both light and dark variants are built eagerly at that point, so any new text style must be added as a static field + init-time assignment + getter, mirrored for light and dark.

Shared layout primitives screens should reuse for consistency with Home (`presentation/home/home_screen.dart` is the reference implementation): `AppDecoratedScaffold` (scaffold + `SafeArea`, no elevation), `EditorialSectionTitle` (the "HEUTE"-style masthead header block), `AppCard` (bordered content card), `IconCircle`, `AppNavigationBar`, and the `AppInlineLoadingState` / `AppInlineErrorState` / `AppFullscreenRecoveryScreen` trio (`presentation/loading/app_loading_screen.dart`) for loading/error states — used consistently from `main.dart` down through individual providers' `.when(loading:, error:)` branches.

### Home-screen widget & background isolate

The Android home-screen widget (`home_widget`) is refreshed by a `workmanager` periodic task (`core/services/background_tasks_service.dart`). Its `workmanagerCallbackDispatcher` runs in a **separate background isolate** with no `ProviderScope`: it opens its own `AppDatabase()` (not the one from `appDatabaseProvider`), receives settings as primitives via `inputData` rather than reading providers, and deliberately avoids platform-channel plugins. Keep any code you add there self-contained the same way.

### Political mode duality

The app has a public mode and an "admin/Marx" mode (`AppMode.public` / `AppMode.adminMarx`, `domain/providers/app_mode_provider.dart`) gating content personalization and the `/admin` route (`adminAccessProvider` redirect guard in `app_router.dart`). Several providers thread `appMode` through alongside user profile/personalization — check how existing resolvers consume it before adding new personalized content paths.
