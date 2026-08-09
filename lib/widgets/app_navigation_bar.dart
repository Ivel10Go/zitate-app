import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;

  /// Wird mit dem Branch-Index gerufen — auch beim Tippen auf den bereits
  /// aktiven Tab, damit die Shell dann auf dessen Startroute zurückspringen
  /// kann (z. B. von `/quiz` zurück auf `/`).
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = <_NavDestination>[
    _NavDestination(label: 'HEUTE', icon: Icons.today_outlined),
    _NavDestination(label: 'FAVORITEN', icon: Icons.favorite_outlined),
    _NavDestination(label: 'EINSTELLUNGEN', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = AppTheme.labelSmall.copyWith(
      color: scheme.onSurface,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );

    return Container(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _destinations.asMap().entries.map((entry) {
              final index = entry.key;
              final destination = entry.value;
              final isActive = index == selectedIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onDestinationSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            destination.icon,
                            size: 16,
                            color: isActive
                                ? scheme.onSurface
                                : scheme.onSurface.withAlpha(
                                    (0.6 * 255).round(),
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            destination.label,
                            style: labelStyle.copyWith(
                              color: isActive
                                  ? scheme.onSurface
                                  : scheme.onSurface.withAlpha(
                                      (0.6 * 255).round(),
                                    ),
                            ),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            opacity: isActive ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 24,
                                height: 1,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
