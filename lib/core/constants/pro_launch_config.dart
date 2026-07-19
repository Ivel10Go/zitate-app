/// Soft-Launch-Schalter für Zitate App Pro.
///
/// Solange `false`, ist die App vollständig kostenlos: [isProProvider]
/// (`core/providers/purchases_provider.dart`) liefert für jeden Nutzer
/// `true`, wodurch alle sonst Pro-gated Funktionen (Denkeratlas, Quiz ohne
/// Tageslimit, personalisierter Feed, PDF-Export) automatisch freigeschaltet
/// sind — und keine Pro-/Paywall-Hinweise (Badges, Einstiegspunkte in
/// Einstellungen/Account) werden angezeigt. Ziel: zuerst eine Nutzerbasis
/// aufbauen, bevor Pro kostenpflichtig angeboten wird.
///
/// Um Pro wieder anzubieten, hier auf `true` setzen — die komplette
/// RevenueCat-Anbindung, Paywall-Seite und Gating-Logik bleiben unverändert
/// bestehen und müssen nicht neu gebaut werden.
const bool kProLaunchEnabled = false;
