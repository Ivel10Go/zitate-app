import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/admin/admin_dashboard_screen.dart';
import '../../presentation/detail/quote_detail_screen_new.dart';
import '../../presentation/favorites/favorites_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/navigation/home_favorites_shell.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/auth/auth_gate_screen.dart';
import '../../presentation/auth/auth_choice_screen.dart';
import '../../presentation/auth/auth_screen.dart';
import '../../presentation/account/account_screen.dart';
import '../../presentation/legal/legal_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/quotes/quote_submission_screen.dart';
import '../../domain/providers/admin_access_provider.dart';

final initialRouteProvider = Provider<String>((Ref ref) => '/auth-gate');

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final initialRoute = ref.watch(initialRouteProvider);
  final isAdmin = ref.watch(adminAccessProvider);

  return GoRouter(
    initialLocation: initialRoute,
    redirect: (context, state) {
      if (state.matchedLocation == '/admin' && !isAdmin) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/auth-gate',
        name: 'auth-gate',
        builder: (context, state) => const AuthGateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeFavoritesShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                name: 'home',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const HomeScreen(showBottomNavigationBar: false),
                ),
              ),
              GoRoute(
                path: '/detail/:id',
                name: 'detail',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return QuoteDetailScreen(quoteId: id);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const FavoritesScreen(showBottomNavigationBar: false),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: const SettingsScreen(showBottomNavigationBar: false),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/legal',
        name: 'legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthChoiceScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const AuthScreen(isSignUp: true),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AccountScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AccountScreen(),
        ),
      ),
      GoRoute(
        path: '/submit-quote',
        name: 'submit-quote',
        builder: (context, state) => const QuoteSubmissionScreen(),
      ),
      // Purchase and premium features routes removed for beta launch
    ],
  );
});
