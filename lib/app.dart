import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/settings_provider.dart';
import 'presentation/loading/app_loading_screen.dart';

class DasKapitalApp extends ConsumerWidget {
  const DasKapitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    return settings.when(
      data: (_) => MaterialApp.router(
        title: 'Quotidian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: const AppInlineLoadingState(
            title: 'Loading settings',
            subtitle: 'Preparing app configuration ...',
          ),
        ),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: AppInlineErrorState(
            title: 'Settings could not be loaded',
            message: 'Error: $err',
          ),
        ),
      ),
    );
  }
}
