/**
 * Design tokens mirrored 1:1 from the app so the promo matches the product.
 * Source of truth: lib/core/theme/app_colors.dart
 */
export const COLORS = {
  paper: "#EDE8DF",
  paperDark: "#E5DFD4",
  ink: "#1A1A1A",
  inkLight: "#555555",
  inkMuted: "#888888",
  rule: "#BBB5AB",
  red: "#C41E1E",
  redDark: "#9B1515",
  onRed: "#FFFFFF",
  saved: "#2A5C3F",
  /** Backdrop behind the device — darker than the app's own dark mode. */
  stage: "#111111",
} as const;

export const FONT_DISPLAY = "PlayfairDisplayPromo";
export const FONT_UI = "IBMPlexSansPromo";

/** Composition geometry (9:16). */
export const VIDEO = { width: 1080, height: 1920, fps: 30 } as const;

/**
 * Device geometry. ~0.49 outer ratio so it reads as a 19.5:9 phone rather
 * than a small tablet. The screen is the app's canvas.
 */
export const PHONE = {
  outerWidth: 860,
  outerHeight: 1760,
  bezel: 16,
  outerRadius: 62,
  screenRadius: 46,
} as const;

export const SCREEN = {
  width: PHONE.outerWidth - PHONE.bezel * 2,
  height: PHONE.outerHeight - PHONE.bezel * 2,
} as const;

/**
 * The app's own spacing scale (dp) blown up for the device mockup.
 * Font sizes are NOT derived from this — 9dp chrome text would be
 * unreadable on video, so small UI text is set explicitly larger.
 */
const SCALE = 2.2;
export const sp = (dp: number) => Math.round(dp * SCALE);

/** Standard scene fade so cuts never hard-pop. */
export const FADE = 8;
