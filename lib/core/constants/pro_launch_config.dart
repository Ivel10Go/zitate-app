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

/// Wie viele Zitate der personalisierte Tages-Feed (`premiumDailyQuotesProvider`)
/// höchstens anzeigt.
///
/// Bewusst eine feste Zahl statt „ein Zitat pro Interesse": Bei vielen
/// Interessen entstand sonst ein überladener Feed, der die Sammlung außerdem
/// pro Tag zu schnell verbraucht hat. Solange [kProLaunchEnabled] `false` ist,
/// bekommt jeder Nutzer diesen vollen Umfang; nach dem Pro-Launch ist dies der
/// Umfang für zahlende Nutzer.
const int kDailyFeedQuoteCount = 5;
