import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_navigation_bar.dart';

class HomeFavoritesShell extends StatelessWidget {
  const HomeFavoritesShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Scaffold statt Column: so verbraucht die Navigationsleiste den unteren
    // System-Inset genau einmal — identisch zu den Screens außerhalb der Shell,
    // die sie über `Scaffold.bottomNavigationBar` einhängen. Sonst springt die
    // Leiste beim Wechsel zwischen Shell- und Nicht-Shell-Screens.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: navigationShell,
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // `initialLocation: true` beim aktiven Tab: ein erneuter Tap springt
        // auf die Startroute des Branches zurück (z. B. /quiz -> /).
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
