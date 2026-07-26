/**
 * Verbatim entries copied from assets/thinkers_quotes.json.
 *
 * Do not paraphrase, shorten or invent text here. The app's content rule is
 * that every quote is a real, sourced utterance and every explanation belongs
 * to that specific quote — a promo that fakes either would misrepresent the
 * product. If a quote is edited in the asset, re-copy it.
 */
export type PromoQuote = {
  id: string;
  author: string;
  year: string;
  source: string;
  chapter: string;
  categories: string[];
  text: string;
  explanationShort: string;
};

/** marx_manifest_001 — the hero quote of the clip. */
export const HERO: PromoQuote = {
  id: "marx_manifest_001",
  author: "Karl Marx & Friedrich Engels",
  year: "1848",
  source: "Manifest der Kommunistischen Partei",
  chapter: "Vorrede",
  categories: ["Politik", "Revolution", "Geschichte"],
  text: "Ein Gespenst geht um in Europa – das Gespenst des Kommunismus.",
  explanationShort:
    "Der Eröffnungssatz des Manifests dreht den Spieß um: Was die Mächtigen als Schreckbild beschwören, erklären Marx und Engels zur realen Kraft.",
};

/** Shown in the card-flip scene to prove the breadth beyond Marx. */
export const OTHERS: PromoQuote[] = [
  {
    id: "sokrates_001",
    author: "Sokrates",
    year: "-399",
    source: "Platon: Apologie des Sokrates",
    chapter: "38a",
    categories: ["Philosophie", "Ethik", "Menschenbild"],
    text: "Ein Leben ohne Selbstprüfung ist für einen Menschen nicht lebenswert.",
    explanationShort:
      "Sokrates' Verteidigung vor Gericht: Lieber sterben als aufhören, das eigene Leben zu befragen.",
  },
  {
    id: "seneca_001",
    author: "Seneca",
    year: "49",
    source: "Von der Kürze des Lebens (De brevitate vitae)",
    chapter: "Kapitel 1",
    categories: ["Philosophie", "Alltag", "Ethik"],
    text: "Nicht wenig Zeit haben wir, sondern viel Zeit vergeuden wir.",
    explanationShort:
      "Das Leben ist nicht zu kurz – wir gehen nur verschwenderisch damit um.",
  },
  {
    id: "engels_antiduehring_002",
    author: "Friedrich Engels",
    year: "1878",
    source: "Anti-Dühring",
    chapter: "Dritter Abschnitt: Sozialismus",
    categories: ["Staat", "Politik", "Revolution"],
    text: "Der Staat wird nicht „abgeschafft“, er stirbt ab.",
    explanationShort:
      "Der Staat verschwindet nicht per Dekret, sondern wird überflüssig, wenn die Klassengegensätze wegfallen, die ihn nötig machen.",
  },
];

/** Total entries in assets/thinkers_quotes.json at the time of writing. */
export const QUOTE_COUNT = 307;

/**
 * Mirrors the app's own negative-year formatting
 * (`thinkers_screen.dart`: `'${quote.year.abs()} v. Chr.'`) so an ancient
 * quote never renders as a raw "-399" on camera.
 */
export const formatYear = (year: string): string => {
  const n = Number(year);
  return n < 0 ? `${Math.abs(n)} v. Chr.` : year;
};
