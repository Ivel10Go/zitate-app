import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({required this.selectedIndex, super.key});

  final int selectedIndex;

  static const _destinations = <_NavDestination>[
    _NavDestination(path: '/', label: 'HEUTE', icon: Icons.today_outlined),
    _NavDestination(
      path: '/favorites',
      label: 'FAVORITEN',
      icon: Icons.favorite_outlined,
    ),
    _NavDestination(
      path: '/settings',
      label: 'EINSTELLUNGEN',
      icon: Icons.settings_outlined,
      isMore: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                    onTap: () {
                      if (destination.isMore) {
                        context.go('/settings');
                        return;
                      }
                      if (isActive || destination.path == null) {
                        return;
                      }
                      context.go(destination.path!);
                    },
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
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? scheme.onSurface
                                  : scheme.onSurface.withAlpha(
                                      (0.6 * 255).round(),
                                    ),
                              letterSpacing: 1.2,
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
  const _NavDestination({
    this.path,
    required this.label,
    required this.icon,
    this.isMore = false,
  });
  final String? path;
  final String label;
  final IconData icon;
  final bool isMore;
}
