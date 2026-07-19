/// Zentrale Konstanten für RevenueCat.
///
/// Die Entitlement-ID war zuvor an vier Stellen hartkodiert (Service-Default,
/// Paywall-Button, Standalone-Paywall). Eine Abweichung hätte bedeutet, dass
/// ein Bildschirm einen zahlenden Nutzer als "frei" behandelt.
abstract final class PurchaseKeys {
  /// Lookup-Key des Pro-Entitlements im RevenueCat-Dashboard.
  /// Muss exakt mit dem dort konfigurierten Entitlement übereinstimmen.
  static const String proEntitlement = 'zitate_app_pro';

  /// Letzter bekannter Pro-Status, lokal gespiegelt.
  ///
  /// Ohne diesen Cache verliert ein zahlender Nutzer bei einem Kaltstart ohne
  /// Netz oder bei fehlgeschlagener SDK-Initialisierung den Pro-Zugriff, bis
  /// RevenueCat wieder erreichbar ist.
  static const String cachedProStatus = 'purchases_cached_pro_status';
}
