import 'dart:async';
import 'dart:developer' as developer;

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../constants/purchase_keys.dart';

class OfferingsFetchResult {
  const OfferingsFetchResult({
    required this.offerings,
    required this.attempts,
    required this.isTimeout,
    this.errorMessage,
  });

  final Offerings? offerings;
  final int attempts;
  final bool isTimeout;
  final String? errorMessage;

  bool get hasOfferings => offerings != null;
}

/// Lightweight wrapper around RevenueCat Purchases SDK for the app.
class PurchasesService {
  PurchasesService._();
  static final PurchasesService instance = PurchasesService._();

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();
  CustomerInfo? _latestCustomerInfo;

  /// `Purchases.configure` wurde erfolgreich aufgerufen. Getrennt von
  /// [_ready], weil `configure` genau einmal pro Prozess laufen darf — ein
  /// zweiter Aufruf beim Wiederholversuch würde die SDK in einen
  /// inkonsistenten Zustand bringen.
  bool _configured = false;

  /// SDK ist konfiguriert *und* der erste CustomerInfo-Abruf hat geklappt.
  bool _ready = false;
  bool _customerInfoListenerAdded = false;
  Future<void>? _inFlightInit;

  CustomerInfo? get latestCustomerInfo => _latestCustomerInfo;
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  /// Ob die SDK einsatzbereit ist. Solange `false`, darf ein fehlender
  /// Pro-Status nicht als "kein Abo" interpretiert werden — er ist unbekannt.
  bool get isReady => _ready;

  void _publishCustomerInfo(CustomerInfo customerInfo) {
    _latestCustomerInfo = customerInfo;
    try {
      _customerInfoController.add(customerInfo);
    } catch (e, st) {
      developer.log('Error publishing customer info: $e', stackTrace: st);
    }
  }

  /// Initialize RevenueCat Purchases SDK with given API key.
  ///
  /// Sicher mehrfach aufrufbar: `Purchases.configure` läuft genau einmal, der
  /// CustomerInfo-Abruf wird bei jedem Versuch wiederholt, bis er einmal
  /// geklappt hat. Parallele Aufrufe teilen sich denselben Future.
  Future<void> init(String apiKey, {bool debugLogs = false}) {
    if (_ready) {
      return Future<void>.value();
    }

    return _inFlightInit ??= _runInit(apiKey, debugLogs: debugLogs)
        .whenComplete(() {
          _inFlightInit = null;
        });
  }

  Future<void> _runInit(String apiKey, {required bool debugLogs}) async {
    try {
      if (!_configured) {
        await Purchases.setLogLevel(debugLogs ? LogLevel.debug : LogLevel.info);
        await Purchases.configure(PurchasesConfiguration(apiKey));
        // Ab hier gilt die SDK als konfiguriert, auch wenn der folgende
        // CustomerInfo-Abruf scheitert. Sonst würde ein Wiederholversuch
        // `configure` ein zweites Mal aufrufen.
        _configured = true;
      }

      if (!_customerInfoListenerAdded) {
        Purchases.addCustomerInfoUpdateListener(_publishCustomerInfo);
        _customerInfoListenerAdded = true;
      }

      // seed initial customer info
      final info = await Purchases.getCustomerInfo();
      _publishCustomerInfo(info);

      _ready = true;
    } on PurchasesError catch (e) {
      developer.log('Purchases SDK error during init: ${e.message}');
      rethrow;
    } catch (e, st) {
      developer.log(
        'Unexpected error during Purchases init: $e',
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Convenience initializer that reads the API key from Dart environment
  /// (`--dart-define=REVENUECAT_API_KEY=...`). Falls back to the app's
  /// public Android SDK key (publishable, safe to embed in the binary).
  Future<void> initFromEnvironment({bool debugLogs = false}) {
    const apiKey = String.fromEnvironment(
      'REVENUECAT_API_KEY',
      defaultValue: 'goog_DIuFsiykgmyWanTtkwNpkdEaRTV',
    );
    return init(apiKey, debugLogs: debugLogs);
  }

  /// Stellt sicher, dass die SDK bereit ist, ohne bei Fehlern zu werfen.
  ///
  /// Der Bootstrap begrenzt die Initialisierung auf 5 Sekunden und behandelt
  /// Fehler als unkritisch. Ohne diesen Wiedereinstieg blieb die SDK danach
  /// für die gesamte Sitzung uninitialisiert — und jeder zahlende Nutzer galt
  /// als Gratisnutzer, bis er die App neu startete.
  Future<bool> ensureInitialized({bool debugLogs = false}) async {
    if (_ready) {
      return true;
    }
    try {
      await initFromEnvironment(debugLogs: debugLogs);
      return _ready;
    } catch (e) {
      developer.log('Purchases ensureInitialized failed: $e');
      return false;
    }
  }

  Future<OfferingsFetchResult> fetchOfferingsWithStatus({
    int maxAttempts = 2,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    Object? lastError;
    bool timedOut = false;

    if (!await ensureInitialized()) {
      return const OfferingsFetchResult(
        offerings: null,
        attempts: 0,
        isTimeout: false,
        errorMessage:
            'Zahlungsdienst konnte nicht initialisiert werden. '
            'Bitte Verbindung prüfen und erneut versuchen.',
      );
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final offerings = await Purchases.getOfferings().timeout(timeout);
        return OfferingsFetchResult(
          offerings: offerings,
          attempts: attempt,
          isTimeout: false,
        );
      } on TimeoutException {
        timedOut = true;
        lastError = 'Zeitüberschreitung beim Laden der Angebote';
        developer.log(
          'Offerings fetch timed out (attempt $attempt/$maxAttempts)',
        );
      } on PurchasesError catch (e) {
        lastError = e.message;
        developer.log(
          'Failed to fetch offerings (attempt $attempt/$maxAttempts): ${e.message}',
        );
      } catch (e, st) {
        lastError = e;
        developer.log(
          'Failed to fetch offerings (attempt $attempt/$maxAttempts): $e',
          stackTrace: st,
        );
      }
    }

    return OfferingsFetchResult(
      offerings: null,
      attempts: maxAttempts,
      isTimeout: timedOut,
      errorMessage: lastError?.toString(),
    );
  }

  Future<Offerings?> fetchOfferings() async {
    final result = await fetchOfferingsWithStatus();
    return result.offerings;
  }

  Future<PurchaseResult> purchasePackage(Package pkg) async {
    if (!await ensureInitialized()) {
      throw StateError('Zahlungsdienst ist nicht verfügbar');
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      return result;
    } on PurchasesError catch (e) {
      developer.log('Purchase failed: ${e.message}');
      rethrow;
    } catch (e, st) {
      developer.log('Unexpected purchase error: $e', stackTrace: st);
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    if (!await ensureInitialized()) {
      throw StateError('Zahlungsdienst ist nicht verfügbar');
    }
    try {
      final info = await Purchases.restorePurchases();
      _publishCustomerInfo(info);
    } on PurchasesError catch (e) {
      developer.log('Restore failed: ${e.message}');
      rethrow;
    }
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  /// Refresh customer info from RevenueCat and push it to listeners.
  Future<CustomerInfo> refreshCustomerInfo() async {
    final info = await Purchases.getCustomerInfo();
    _publishCustomerInfo(info);
    return info;
  }

  Future<CustomerInfo?> refreshCustomerInfoSafe() async {
    if (!await ensureInitialized()) {
      return null;
    }
    try {
      return await refreshCustomerInfo();
    } on PurchasesError catch (e) {
      developer.log('Customer info refresh failed: ${e.message}');
      return null;
    } catch (e, st) {
      developer.log('Customer info refresh failed: $e', stackTrace: st);
      return null;
    }
  }

  /// Associate an app user id with RevenueCat (login). Safe to call repeatedly.
  Future<void> logIn(String appUserId) async {
    if (!await ensureInitialized()) {
      throw StateError('Purchases SDK ist nicht initialisiert');
    }
    try {
      final result = await Purchases.logIn(appUserId);
      _publishCustomerInfo(result.customerInfo);
    } catch (e, st) {
      developer.log('Purchases logIn failed: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Clears RevenueCat identity for the current device.
  ///
  /// Muss beim Abmelden laufen: sonst behält das Gerät die Entitlements des
  /// vorherigen Kontos, und der nächste (nicht angemeldete) Nutzer sieht
  /// fremde Pro-Inhalte.
  Future<void> logOut() async {
    if (!await ensureInitialized()) {
      return;
    }
    try {
      final info = await Purchases.logOut();
      _publishCustomerInfo(info);
    } catch (e, st) {
      // Ein anonymer Nutzer kann nicht ausgeloggt werden — das ist kein
      // Fehlerfall, den der Abmeldevorgang abbrechen dürfte.
      developer.log('Purchases logOut failed: $e', stackTrace: st);
    }
  }

  bool hasProEntitlement(
    CustomerInfo info, {
    String entitlementId = PurchaseKeys.proEntitlement,
  }) {
    final ent = info.entitlements.all[entitlementId];
    return ent?.isActive ?? false;
  }

  /// Present a RevenueCat Paywall if needed for a required entitlement.
  Future<PaywallResult> presentPaywallIfNeeded({
    String? requiredEntitlementId,
  }) async {
    try {
      if (requiredEntitlementId != null) {
        final result = await RevenueCatUI.presentPaywallIfNeeded(
          requiredEntitlementId,
        );
        return result;
      }

      final result = await RevenueCatUI.presentPaywall();
      return result;
    } catch (e, st) {
      developer.log('Error presenting paywall: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Present the RevenueCat Customer Center (if available for the current plan/SDK).
  /// This will open a native Customer Center UI where supported.
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e, st) {
      developer.log(
        'Customer Center not available or failed to present: $e',
        stackTrace: st,
      );
      rethrow;
    }
  }
}
