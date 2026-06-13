import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_navigation_bar.dart';

class HomeFavoritesShell extends StatelessWidget {
  const HomeFavoritesShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: navigationShell),
        AppNavigationBar(selectedIndex: navigationShell.currentIndex),
      ],
    );
  }
}
