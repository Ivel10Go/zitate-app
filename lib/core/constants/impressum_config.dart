/// Impressumsdaten nach § 5 DDG (Digitale-Dienste-Gesetz, löste 2024 § 5 TMG ab)
/// und § 18 Abs. 2 MStV.
///
/// Alle Werte sind Platzhalter und können entweder hier direkt ersetzt oder
/// zur Buildzeit per `--dart-define` überschrieben werden, z. B.:
///
/// ```
/// flutter build appbundle \
///   --dart-define=LEGAL_PROVIDER_NAME="Musterfirma GmbH" \
///   --dart-define=LEGAL_PROVIDER_ADDRESS="Musterstraße 12, 12345 Berlin"
/// ```
///
/// Felder, die auf den Platzhalterwert zurückfallen, werden im Impressum-Screen
/// sichtbar als „nicht konfiguriert" markiert — ein unvollständiges Impressum ist
/// abmahnfähig, deshalb wird der Zustand nicht stillschweigend versteckt.
///
/// Pflichtangaben (§ 5 Abs. 1 DDG):
///   1. Name und ladungsfähige Anschrift (kein Postfach), bei juristischen
///      Personen zusätzlich Rechtsform und Vertretungsberechtigte
///   2. Angaben zur schnellen elektronischen Kontaktaufnahme: E-Mail *und* ein
///      zweiter unmittelbarer Weg (Telefon oder Kontaktformular)
///   3. Zuständige Aufsichtsbehörde, sofern die Tätigkeit zulassungspflichtig ist
///   4. Register (Handels-, Vereins-, Partnerschafts-, Genossenschaftsregister)
///      samt Registernummer, sofern vorhanden
///   5. Bei reglementierten Berufen: Kammer, Berufsbezeichnung, Verleihungsstaat
///      und die berufsrechtlichen Regelungen
///   6. Umsatzsteuer-Identifikationsnummer (§ 27a UStG) bzw.
///      Wirtschafts-Identifikationsnummer (§ 139c AO), sofern vorhanden
///   7. Bei AG/KGaA/GmbH in Abwicklung oder Liquidation: entsprechender Hinweis
///
/// Zusätzlich, sobald die App journalistisch-redaktionelle Inhalte anbietet
/// (bei kuratierten und kommentierten Inhalten regelmäßig der Fall):
///   - Verantwortlicher i. S. v. § 18 Abs. 2 MStV mit Name und Anschrift
///
/// Nicht mehr erforderlich: der Link auf die EU-Online-Streitbeilegungsplattform
/// (OS-Plattform), die zum 20.07.2025 eingestellt wurde. Der Hinweis auf die
/// (Nicht-)Teilnahme an einem Verbraucherschlichtungsverfahren nach § 36 VSBG
/// bleibt für Unternehmer mit mehr als zehn Beschäftigten Pflicht.
library;

/// Wert, der anzeigt, dass ein Feld noch nicht befüllt wurde.
const String kImpressumPlaceholder = 'NICHT KONFIGURIERT';

/// Name bzw. Firma des Diensteanbieters, inkl. Rechtsform.
/// Beispiel: "Musterfirma GmbH" oder "Max Mustermann (Einzelunternehmer)".
const String kLegalProviderName = String.fromEnvironment(
  'LEGAL_PROVIDER_NAME',
  defaultValue: kImpressumPlaceholder,
);

/// Ladungsfähige Anschrift — Straße, Hausnummer, PLZ, Ort. Kein Postfach.
/// Beispiel: "Musterstraße 12, 12345 Berlin, Deutschland".
const String kLegalProviderAddress = String.fromEnvironment(
  'LEGAL_PROVIDER_ADDRESS',
  defaultValue: kImpressumPlaceholder,
);

/// Vertretungsberechtigte Person(en) bei juristischen Personen.
/// Beispiel: "Geschäftsführerin: Erika Mustermann".
/// Bei Einzelunternehmen leer lassen bzw. auf "-" setzen.
const String kLegalProviderRepresentative = String.fromEnvironment(
  'LEGAL_PROVIDER_REPRESENTATIVE',
  defaultValue: kImpressumPlaceholder,
);

/// E-Mail-Adresse für die unmittelbare Kontaktaufnahme.
/// Beispiel: "kontakt@beispiel.de".
const String kLegalProviderEmail = String.fromEnvironment(
  'LEGAL_PROVIDER_EMAIL',
  defaultValue: kImpressumPlaceholder,
);

/// Zweiter schneller Kontaktweg neben der E-Mail — Telefonnummer oder die URL
/// eines Kontaktformulars mit zugesagter Antwortzeit.
/// Beispiel: "+49 30 12345678".
const String kLegalProviderPhone = String.fromEnvironment(
  'LEGAL_PROVIDER_PHONE',
  defaultValue: kImpressumPlaceholder,
);

/// Registergericht und Registernummer, sofern eine Eintragung besteht.
/// Beispiel: "Amtsgericht Berlin-Charlottenburg, HRB 123456".
const String kLegalProviderRegister = String.fromEnvironment(
  'LEGAL_PROVIDER_REGISTER',
  defaultValue: kImpressumPlaceholder,
);

/// Umsatzsteuer-Identifikationsnummer nach § 27a UStG, sofern vorhanden.
/// Beispiel: "DE123456789".
const String kLegalProviderVatId = String.fromEnvironment(
  'LEGAL_PROVIDER_VAT_ID',
  defaultValue: kImpressumPlaceholder,
);

/// Zuständige Aufsichtsbehörde, sofern die Tätigkeit einer Zulassung bedarf.
/// Für eine reine Zitate-App in der Regel nicht einschlägig — dann "-" setzen.
const String kLegalProviderSupervisoryAuthority = String.fromEnvironment(
  'LEGAL_PROVIDER_SUPERVISORY_AUTHORITY',
  defaultValue: kImpressumPlaceholder,
);

/// Verantwortlicher für journalistisch-redaktionelle Inhalte nach
/// § 18 Abs. 2 MStV — Name und vollständige Anschrift.
/// Beispiel: "Max Mustermann, Musterstraße 12, 12345 Berlin".
const String kLegalContentResponsible = String.fromEnvironment(
  'LEGAL_CONTENT_RESPONSIBLE',
  defaultValue: kImpressumPlaceholder,
);

/// Ob eine Bereitschaft zur Teilnahme an einem Streitbeilegungsverfahren vor
/// einer Verbraucherschlichtungsstelle besteht (§ 36 VSBG).
const bool kLegalDisputeResolutionParticipation = bool.fromEnvironment(
  'LEGAL_DISPUTE_RESOLUTION',
);

/// True, sobald alle Pflichtfelder gesetzt wurden.
bool get kImpressumIsConfigured => <String>[
  kLegalProviderName,
  kLegalProviderAddress,
  kLegalProviderEmail,
  kLegalProviderPhone,
  kLegalContentResponsible,
].every((String value) => value.trim() != kImpressumPlaceholder);
