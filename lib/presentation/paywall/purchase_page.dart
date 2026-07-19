import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:purchases_flutter/purchases_flutter.dart'
    show Offerings, Package, PackageType, PurchasesError, PurchasesErrorCode;

import '../../core/providers/purchases_provider.dart';
import '../../core/services/purchases_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../loading/app_loading_screen.dart';

/// Editorial paywall page ("Verlagsanzeige"), see docs/paywall_design.md.
class PurchasePage extends ConsumerStatefulWidget {
  const PurchasePage({super.key});

  @override
  ConsumerState<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends ConsumerState<PurchasePage> {
  List<Package> _packages = <Package>[];
  Package? _selectedPackage;
  bool _loading = false;
  bool _purchaseBusy = false;
  bool _restoreBusy = false;
  bool _customerCenterBusy = false;
  String? _errorMessage;

  static const _proFeatures = <String>[
    'Personalisierter Zitate-Feed',
    'Kompletter Denkeratlas mit Suche',
    'Zitat-Quiz ohne Tageslimit',
    'PDF-Export deiner Favoriten',
  ];

  @override
  void initState() {
    super.initState();
    _refreshEntitlementSnapshot();
    _loadOfferings();
  }

  Future<void> _refreshEntitlementSnapshot() async {
    await PurchasesService.instance.refreshCustomerInfoSafe();
  }

  Future<void> _loadOfferings() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await PurchasesService.instance.fetchOfferingsWithStatus();
      final off = result.offerings;
      final packages = _packagesForDisplay(off);

      if (!mounted) {
        return;
      }
      setState(() {
        _packages = packages;
        _selectedPackage = _preferredPackage(packages);
        if (off == null) {
          _errorMessage = result.isTimeout
              ? 'Angebote konnten nicht rechtzeitig geladen werden. Bitte erneut versuchen.'
              : 'Angebote konnten nicht geladen werden. Bitte Verbindung prüfen und erneut versuchen.';
        } else if (packages.isEmpty) {
          _errorMessage =
              'Derzeit sind keine Angebote verfügbar. Bitte später erneut versuchen.';
        } else {
          _errorMessage = null;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Angebote konnten nicht geladen werden: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _buyPackage(Package pkg) async {
    if (_purchaseBusy) {
      return;
    }
    setState(() {
      _purchaseBusy = true;
    });
    try {
      await PurchasesService.instance.purchasePackage(pkg);
      final info = await PurchasesService.instance.refreshCustomerInfo();
      if (PurchasesService.instance.hasProEntitlement(info)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danke — Zitate App Pro ist nun aktiv!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kauf verarbeitet. Pro-Status wird noch aktualisiert — bitte gedulde dich einen Moment.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PurchasesError catch (e) {
      if (!mounted) return;
      final cancelled = e.code == PurchasesErrorCode.purchaseCancelledError;
      if (cancelled) {
        // Abbruch ist kein Fehler — Seite bleibt unverändert.
        return;
      }
      final networkError = e.code == PurchasesErrorCode.networkError;
      final message = networkError
          ? 'Netzwerkfehler beim Kauf. Bitte Verbindung überprüfen und erneut versuchen.'
          : 'Kauf nicht abgeschlossen: ${e.message} — Bitte erneut versuchen.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Kauf: $e — Bitte erneut versuchen.'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _purchaseBusy = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    if (_restoreBusy) {
      return;
    }
    setState(() {
      _restoreBusy = true;
    });
    try {
      await PurchasesService.instance.restorePurchases();
      final info = await PurchasesService.instance.refreshCustomerInfo();
      if (PurchasesService.instance.hasProEntitlement(info)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Käufe wiederhergestellt — Pro ist aktiv!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine aktiven Käufe auf diesem Gerät gefunden.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PurchasesError catch (e) {
      if (!mounted) return;
      final networkError = e.code == PurchasesErrorCode.networkError;
      final message = networkError
          ? 'Netzwerkfehler beim Wiederherstellen. Bitte Verbindung überprüfen.'
          : 'Wiederherstellung fehlgeschlagen: ${e.message} — Bitte erneut versuchen.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fehler beim Wiederherstellen: $e — Bitte erneut versuchen.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _restoreBusy = false;
        });
      }
    }
  }

  Future<void> _openCustomerCenter() async {
    if (_customerCenterBusy) {
      return;
    }
    setState(() {
      _customerCenterBusy = true;
    });
    try {
      await PurchasesService.instance.presentCustomerCenter();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Kontocenter ist auf diesem Gerät nicht verfügbar. Bitte versuche es später oder kontaktiere den Support.',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _customerCenterBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppDecoratedScaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: <Widget>[
          _Masthead(scheme: scheme),
          const SizedBox(height: 24),
          if (isPro) ...<Widget>[
            _ProActiveCard(scheme: scheme),
            const SizedBox(height: 24),
          ],
          _FeatureList(scheme: scheme, features: _proFeatures),
          const SizedBox(height: 24),
          if (!isPro) ...<Widget>[
            ..._buildOfferingArea(scheme),
            const SizedBox(height: 20),
          ],
          _buildSecondaryActions(scheme),
          const SizedBox(height: 16),
          Container(height: 1, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'Der freie Kern der App bleibt voll nutzbar. Jederzeit kündbar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              onTap: () => context.push('/legal'),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  'AGB · Datenschutz',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOfferingArea(ColorScheme scheme) {
    if (_loading) {
      return const <Widget>[
        AppInlineLoadingState(
          title: 'Angebote werden geladen',
          subtitle: 'Preise und Pakete werden abgerufen ...',
        ),
      ];
    }

    if (_errorMessage != null) {
      return <Widget>[
        AppInlineErrorState(
          title: 'Angebote nicht verfügbar',
          message: _errorMessage!,
          onRetry: _loadOfferings,
        ),
      ];
    }

    if (_packages.isEmpty) {
      return <Widget>[
        Text(
          'Derzeit sind keine Angebote verfügbar.',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _loadOfferings,
          child: const Text('Erneut laden'),
        ),
      ];
    }

    return <Widget>[
      for (final pkg in _packages) ...<Widget>[
        _PackageCard(
          package: pkg,
          label: _packageLabel(pkg),
          periodSuffix: _periodSuffix(pkg.packageType),
          recommended: pkg.packageType == PackageType.annual,
          selected: _selectedPackage?.identifier == pkg.identifier,
          scheme: scheme,
          onTap: () => setState(() => _selectedPackage = pkg),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      _buildPurchaseCta(scheme),
    ];
  }

  Widget _buildPurchaseCta(ColorScheme scheme) {
    final selected = _selectedPackage;
    final enabled = selected != null && !_purchaseBusy;
    final label = selected == null
        ? 'PRO FREISCHALTEN'
        : 'PRO FREISCHALTEN — ${selected.storeProduct.priceString}';

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled ? AppColors.red : scheme.outline,
        child: InkWell(
          onTap: enabled ? () => _buyPackage(selected) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _purchaseBusy
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.redOnRed,
                      ),
                    ),
                  )
                : Text(
                    label,
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
    );
  }

  Widget _buildSecondaryActions(ColorScheme scheme) {
    return Column(
      children: <Widget>[
        _TextAction(
          label: 'Käufe wiederherstellen',
          busy: _restoreBusy,
          color: scheme.onSurface.withValues(alpha: 0.75),
          onTap: _restore,
        ),
        const SizedBox(height: 4),
        _TextAction(
          label: 'Abo verwalten',
          busy: _customerCenterBusy,
          color: scheme.onSurfaceVariant,
          onTap: _openCustomerCenter,
        ),
      ],
    );
  }

  Package? _preferredPackage(List<Package> packages) {
    for (final pkg in packages) {
      if (pkg.packageType == PackageType.annual) {
        return pkg;
      }
    }
    return packages.isNotEmpty ? packages.first : null;
  }

  List<Package> _packagesForDisplay(Offerings? offerings) {
    final offering = offerings?.current;
    final packages = <Package>[];

    if (offering != null && offering.availablePackages.isNotEmpty) {
      packages.addAll(offering.availablePackages);
    } else if (offerings != null) {
      for (final candidate in offerings.all.values) {
        if (candidate.availablePackages.isNotEmpty) {
          packages.addAll(candidate.availablePackages);
          break;
        }
      }
    }

    packages.sort((a, b) {
      final weightA = _packageSortWeight(a.packageType);
      final weightB = _packageSortWeight(b.packageType);
      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      }
      return a.storeProduct.price.compareTo(b.storeProduct.price);
    });

    return packages;
  }

  int _packageSortWeight(PackageType type) {
    switch (type) {
      case PackageType.lifetime:
        return 0;
      case PackageType.annual:
        return 1;
      case PackageType.monthly:
        return 2;
      case PackageType.sixMonth:
        return 3;
      case PackageType.threeMonth:
        return 4;
      case PackageType.twoMonth:
        return 5;
      case PackageType.weekly:
        return 6;
      case PackageType.custom:
      case PackageType.unknown:
        return 7;
    }
  }

  String _packageLabel(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.lifetime:
        return 'LEBENSLANG';
      case PackageType.annual:
        return 'JÄHRLICH';
      case PackageType.monthly:
        return 'MONATLICH';
      case PackageType.sixMonth:
        return '6 MONATE';
      case PackageType.threeMonth:
        return '3 MONATE';
      case PackageType.twoMonth:
        return '2 MONATE';
      case PackageType.weekly:
        return 'WÖCHENTLICH';
      case PackageType.custom:
      case PackageType.unknown:
        return pkg.identifier.toUpperCase();
    }
  }

  String _periodSuffix(PackageType type) {
    switch (type) {
      case PackageType.lifetime:
        return 'einmalig';
      case PackageType.annual:
        return '/ Jahr';
      case PackageType.monthly:
        return '/ Monat';
      case PackageType.sixMonth:
        return '/ 6 Monate';
      case PackageType.threeMonth:
        return '/ 3 Monate';
      case PackageType.twoMonth:
        return '/ 2 Monate';
      case PackageType.weekly:
        return '/ Woche';
      case PackageType.custom:
      case PackageType.unknown:
        return '';
    }
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final overlineStyle = GoogleFonts.ibmPlexSans(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      letterSpacing: 1.8,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('ZITATE APP', style: overlineStyle),
            const Spacer(),
            Text('ANZEIGE', style: overlineStyle),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: scheme.onSurface),
        const SizedBox(height: 3),
        Container(height: 1, color: scheme.onSurface),
        const SizedBox(height: 18),
        Text(
          'Pro',
          style: GoogleFonts.playfairDisplay(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: scheme.onSurface,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tiefere Inhalte. Mehr Kontext.',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: scheme.outline),
      ],
    );
  }
}

class _ProActiveCard extends StatelessWidget {
  const _ProActiveCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'PRO AKTIV',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.saved,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dein Upgrade ist freigeschaltet.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Käufe lassen sich jederzeit wiederherstellen.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.scheme, required this.features});

  final ColorScheme scheme;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'WAS PRO FREISCHALTET',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '✦',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: AppColors.red,
                    height: 1.4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.5,
                      color: scheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.label,
    required this.periodSuffix,
    required this.recommended,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final Package package;
  final String label;
  final String periodSuffix;
  final bool recommended;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: selected ? AppColors.red : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.red : scheme.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (recommended)
                  Text(
                    'EMPFOHLEN',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                      letterSpacing: 1.2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  package.storeProduct.priceString,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  periodSuffix,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.busy,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11.5,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
                ),
        ),
      ),
    );
  }
}
