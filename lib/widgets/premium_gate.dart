import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers/purchases_provider.dart';
import '../core/theme/app_colors.dart';
import 'app_decorated_scaffold.dart';

/// Premium feature gate that shows content for Pro users or a teaser for free users.
///
/// **Immediate Entitlement Sync (MON-05)**:
/// - Watches [isProProvider] which streams latest entitlement state from RevenueCat
/// - When purchase/restore succeeds, stream emits new CustomerInfo
/// - Riverpod automatically rebuilds this widget with new isPremium value
/// - No app restart needed; gate updates in real-time during purchase flow
///
/// The teaser is a full-screen editorial page (own scaffold), so this gate is
/// meant to wrap entire screens/routes, not inline widgets.
///
/// **Usage:**
/// ```dart
/// PremiumGate(
///   featureName: 'Denkeratlas',
///   child: ThinkersScreen(),
/// )
/// ```
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    required this.child,
    this.featureName = 'Pro-Feature',
    this.featureDescription = 'Dieses Feature ist Teil von Zitate App Pro.',
    super.key,
  });

  final Widget child;
  final String featureName;
  final String featureDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    if (isPro) {
      return child;
    }

    return _PremiumTeaserScreen(
      featureName: featureName,
      featureDescription: featureDescription,
    );
  }
}

class _PremiumTeaserScreen extends StatelessWidget {
  const _PremiumTeaserScreen({
    required this.featureName,
    required this.featureDescription,
  });

  final String featureName;
  final String featureDescription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppDecoratedScaffold(
      appBar: null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ZITATE APP PRO',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 2, color: AppColors.red),
                const SizedBox(height: 14),
                Text(
                  featureName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  featureDescription,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.red,
                    child: InkWell(
                      onTap: () => context.push('/paywall'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          'PRO FREISCHALTEN',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redOnRed,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Der freie Kern der App bleibt voll nutzbar. Jederzeit kündbar.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
