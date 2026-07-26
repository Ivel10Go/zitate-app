import { QUOTE_COUNT } from "./quotes";

export type Palette = "ink" | "paper" | "red";

export type Feature = {
  /** Slug picking the visual fragment in visuals.tsx. */
  visual:
    | "quote"
    | "einordnung"
    | "atlas"
    | "quiz"
    | "favorites"
    | "widget"
    | "profile"
    | "sync"
    | "submit";
  name: string;
  description: string;
  palette: Palette;
};

/**
 * The app's actual surface, taken from the router (`app_router.dart`),
 * the settings screen and the Pro page — not invented.
 *
 * Palettes alternate on purpose: the cut between two same-coloured scenes
 * reads as a glitch, the alternation reads as rhythm.
 */
export const FEATURES: Feature[] = [
  {
    visual: "quote",
    name: "Tageszitat",
    description: "Jeden Tag ein belegtes Zitat – mit Quelle, Werk und Jahr.",
    palette: "ink",
  },
  {
    visual: "einordnung",
    name: "Einordnung",
    description:
      "Was der Satz wirklich meint und wo er falsch zitiert wird.",
    palette: "paper",
  },
  {
    visual: "atlas",
    name: "Denkeratlas",
    description: `${QUOTE_COUNT} Zitate von Heraklit bis Engels durchstöbern.`,
    palette: "ink",
  },
  {
    visual: "quiz",
    name: "Zitat-Quiz",
    description: "Erkennst du die Quelle? 10 Fragen täglich.",
    palette: "red",
  },
  {
    visual: "favorites",
    name: "Favoriten",
    description: "Speichern, als Zitatkarte teilen, im Archiv wiederfinden.",
    palette: "paper",
  },
  {
    visual: "widget",
    name: "Widget",
    description: "Das Tageszitat auf dem Homescreen. Plus tägliche Erinnerung.",
    palette: "ink",
  },
  {
    visual: "profile",
    name: "Dein Profil",
    description: "Interessen und politische Haltung steuern deinen Feed.",
    palette: "paper",
  },
  {
    visual: "sync",
    name: "Offline & Sync",
    description: "Ohne Netz lesbar. Über alle Geräte synchron.",
    palette: "ink",
  },
  {
    visual: "submit",
    name: "Mitmachen",
    description: "Eigene Zitate einreichen – geprüft, bevor sie erscheinen.",
    palette: "red",
  },
];

/** Resolved colours per palette. Only paper / ink / red exist in the brand. */
export const PALETTES: Record<
  Palette,
  { bg: string; fg: string; accent: string; muted: string; onAccent: string }
> = {
  ink: {
    bg: "#121212",
    fg: "#EDE8DF",
    accent: "#C41E1E",
    muted: "#8E8880",
    onAccent: "#FFFFFF",
  },
  paper: {
    bg: "#EDE8DF",
    fg: "#1A1A1A",
    accent: "#C41E1E",
    muted: "#6B655C",
    onAccent: "#FFFFFF",
  },
  red: {
    bg: "#C41E1E",
    fg: "#FFFFFF",
    accent: "#1A1A1A",
    muted: "rgba(255,255,255,0.78)",
    onAccent: "#FFFFFF",
  },
};
