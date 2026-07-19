import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show CustomerInfo;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/providers/user_profile_provider.dart';
import '../constants/pro_launch_config.dart';
import '../constants/purchase_keys.dart';
import '../services/purchases_service.dart';

/// Woher der aktuelle Pro-Status stammt.
enum EntitlementSource {
  /// Noch nichts geladen — Status unbekannt.
  unknown,

  /// Aus dem lokalen Cache des letzten bekannten Zustands.
  cached,

  /// Direkt von RevenueCat bestätigt.
  live,
}

@immutable
class EntitlementState {
  const EntitlementState({
    required this.isPro,
    required this.source,
    this.isRefreshing = false,
  });

  const EntitlementState.unknown()
    : isPro = false,
      source = EntitlementSource.unknown,
      isRefreshing = true;

  final bool isPro;
  final EntitlementSource source;
  final bool isRefreshing;

  EntitlementState copyWith({
    bool? isPro,
    EntitlementSource? source,
    bool? isRefreshing,
  }) {
    return EntitlementState(
      isPro: isPro ?? this.isPro,
      source: source ?? this.source,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Hält den Pro-Status über RevenueCat, App-Lifecycle und Kaltstarts hinweg.
///
/// Der Kern: ein *nicht bestätigter* Zustand ist nicht dasselbe wie "kein
/// Abo". Zuvor lieferte der Provider bei Ladefehlern und während des Ladens
/// pauschal `false` — ein zahlender Nutzer verlor damit bei jedem Kaltstart
/// ohne Netz seine Inhalte. Jetzt gilt der zuletzt bestätigte Status weiter,
/// bis RevenueCat etwas anderes sagt.
class EntitlementNotifier extends StateNotifier<EntitlementState>
    with WidgetsBindingObserver {
  EntitlementNotifier() : super(const EntitlementState.unknown()) {
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  final PurchasesService _service = PurchasesService.instance;
  StreamSubscription<CustomerInfo>? _subscription;

  Future<void> _bootstrap() async {
    await _restoreCachedStatus();

    _subscription = _service.customerInfoStream.listen(
      _applyCustomerInfo,
      onError: (Object error) {
        debugPrint('[Entitlement] Customer info stream error: $error');
        state = state.copyWith(isRefreshing: false);
      },
    );

    final seeded = _service.latestCustomerInfo;
    if (seeded != null) {
      _applyCustomerInfo(seeded);
    }

    await refresh();
  }

  Future<void> _restoreCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool(PurchaseKeys.cachedProStatus);
      if (cached != null && state.source == EntitlementSource.unknown) {
        state = EntitlementState(
          isPro: cached,
          source: EntitlementSource.cached,
          isRefreshing: true,
        );
      }
    } catch (e) {
      debugPrint('[Entitlement] Cached status read failed: $e');
    }
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final isPro = _service.hasProEntitlement(info);
    state = EntitlementState(
      isPro: isPro,
      source: EntitlementSource.live,
      isRefreshing: false,
    );
    unawaited(_persist(isPro));
  }

  Future<void> _persist(bool isPro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PurchaseKeys.cachedProStatus, isPro);
    } catch (e) {
      debugPrint('[Entitlement] Cached status write failed: $e');
    }
  }

  /// Holt den Status neu von RevenueCat. Schlägt der Abruf fehl, bleibt der
  /// bisherige Zustand bestehen — nur das Refresh-Flag fällt zurück.
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    final info = await _service.refreshCustomerInfoSafe();
    if (!mounted) {
      return;
    }
    if (info == null) {
      state = state.copyWith(isRefreshing: false);
      return;
    }
    _applyCustomerInfo(info);
  }

  // Parameter bewusst nicht `state` genannt: das würde den State des
  // StateNotifiers in diesem Methodenrumpf verdecken.
  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Käufe und Kündigungen passieren im Play Store, also außerhalb der App.
    // Ohne diesen Abgleich bemerkt die App eine dort geänderte Mitgliedschaft
    // erst beim nächsten Kaltstart.
    if (lifecycleState == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}

final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, EntitlementState>((ref) {
      return EntitlementNotifier();
    });

/// Ob der Nutzer Pro-Zugriff hat.
///
/// Während eines laufenden Abgleichs gilt der zuletzt bestätigte Status — ein
/// zahlender Nutzer wird nie kurzzeitig ausgesperrt.
final isProProvider = Provider<bool>((ref) {
  if (!kProLaunchEnabled) {
    return true;
  }

  final debugPremiumOverride =
      kDebugMode && ref.watch(userProfileProvider).premiumTestEnabled;
  if (debugPremiumOverride) {
    return true;
  }

  return ref.watch(entitlementProvider).isPro;
});

/// Ob der Pro-Status noch nie von RevenueCat bestätigt wurde.
/// Nützlich für UI, die einen unsicheren Zustand kennzeichnen soll.
final entitlementUnconfirmedProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).source != EntitlementSource.live;
});
