import React from "react";
import { Easing, interpolate } from "remotion";
import { FONT_DISPLAY, FONT_UI } from "./theme";
import { PALETTES, type Feature, type Palette } from "./features";
import { HERO, OTHERS, QUOTE_COUNT, formatYear } from "./quotes";

const EASE_OUT = Easing.bezier(0.16, 1, 0.3, 1);

type VisualProps = { frame: number; palette: Palette };

/** Staggered entrance shared by every fragment row. */
const rowIn = (frame: number, index: number) => ({
  opacity: interpolate(frame, [14 + index * 5, 30 + index * 5], [0, 1], {
    extrapolateLeft: "clamp" as const,
    extrapolateRight: "clamp" as const,
  }),
  translate:
    "0px " +
    interpolate(frame, [14 + index * 5, 36 + index * 5], [24, 0], {
      extrapolateLeft: "clamp" as const,
      extrapolateRight: "clamp" as const,
      easing: EASE_OUT,
    }).toFixed(2) +
    "px",
});

/** Hairline-bordered surface used by most fragments. */
const Panel: React.FC<{
  palette: Palette;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ palette, children, style }) => {
  const p = PALETTES[palette];
  return (
    <div
      style={{
        border: `1px solid ${palette === "paper" ? "#1A1A1A" : p.fg}`,
        background: palette === "paper" ? "#EDE8DF" : "rgba(237,232,223,0.05)",
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** 01 — the real quote card, trimmed to kicker + line. */
const QuoteVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  return (
    <div style={rowIn(frame, 0)}>
      <div
        style={{
          background: p.accent,
          padding: "18px 28px",
          fontFamily: FONT_UI,
          fontSize: 24,
          fontWeight: 700,
          letterSpacing: 2.6,
          color: palette === "red" ? "#FFFFFF" : "#FFFFFF",
        }}
      >
        {HERO.author.toUpperCase()} · {HERO.year}
      </div>
      <Panel palette={palette} style={{ padding: "40px 28px 34px" }}>
        <div
          style={{
            fontFamily: FONT_DISPLAY,
            fontSize: 58,
            lineHeight: 1.26,
            color: p.fg,
            letterSpacing: -0.5,
          }}
        >
          {HERO.text}
        </div>
        <div style={{ width: 62, height: 4, background: p.accent, marginTop: 30 }} />
        <div
          style={{
            fontFamily: FONT_UI,
            fontSize: 24,
            fontWeight: 500,
            letterSpacing: 1.6,
            color: p.muted,
            marginTop: 22,
            textTransform: "uppercase",
          }}
        >
          {HERO.source}
        </div>
      </Panel>
    </div>
  );
};

/** 02 — the insight block: red band plus the quote's own explanation. */
const EinordnungVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  return (
    <div style={rowIn(frame, 0)}>
      <div
        style={{
          background: p.accent,
          padding: "16px 28px",
          fontFamily: FONT_UI,
          fontSize: 24,
          fontWeight: 700,
          letterSpacing: 3.2,
          color: "#FFFFFF",
        }}
      >
        EINORDNUNG
      </div>
      <Panel palette={palette} style={{ padding: "34px 28px" }}>
        <div
          style={{
            fontFamily: FONT_DISPLAY,
            fontSize: 44,
            lineHeight: 1.4,
            color: p.fg,
          }}
        >
          {HERO.explanationShort}
        </div>
      </Panel>
    </div>
  );
};

/** 03 — an index of thinkers, the way the Denkeratlas lists them. */
const AtlasVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  const rows = [
    { name: "Heraklit", year: "-500" },
    { name: "Sokrates", year: "-399" },
    { name: "Seneca", year: "49" },
    { name: "Karl Marx", year: "1867" },
    { name: "Friedrich Engels", year: "1878" },
  ];
  return (
    <div style={{ width: "100%" }}>
      {rows.map((r, i) => (
        <div
          key={r.name}
          style={{
            ...rowIn(frame, i),
            display: "flex",
            alignItems: "baseline",
            justifyContent: "space-between",
            padding: "22px 4px",
            borderBottom: `1px solid ${palette === "paper" ? "#BBB5AB" : "rgba(237,232,223,0.22)"}`,
          }}
        >
          <span
            style={{
              fontFamily: FONT_DISPLAY,
              fontSize: 52,
              fontWeight: 700,
              color: p.fg,
              letterSpacing: -0.8,
            }}
          >
            {r.name}
          </span>
          <span
            style={{
              fontFamily: FONT_UI,
              fontSize: 26,
              fontWeight: 600,
              letterSpacing: 2,
              color: p.muted,
            }}
          >
            {formatYear(r.year).toUpperCase()}
          </span>
        </div>
      ))}
      <div
        style={{
          ...rowIn(frame, rows.length),
          fontFamily: FONT_UI,
          fontSize: 26,
          fontWeight: 700,
          letterSpacing: 3,
          color: p.accent,
          paddingTop: 26,
        }}
      >
        + {QUOTE_COUNT - rows.length} WEITERE
      </div>
    </div>
  );
};

/** 04 — a quiz question with its options, one marked correct. */
const QuizVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  const options = [
    { label: "Manifest der Kommunistischen Partei", correct: true },
    { label: "Das Kapital, Band I", correct: false },
    { label: "Kritik des Gothaer Programms", correct: false },
  ];
  return (
    <div style={{ width: "100%" }}>
      <div
        style={{
          ...rowIn(frame, 0),
          fontFamily: FONT_DISPLAY,
          fontSize: 46,
          lineHeight: 1.3,
          color: p.fg,
          marginBottom: 34,
        }}
      >
        „Ein Gespenst geht um in Europa …" – woraus?
      </div>
      {options.map((o, i) => (
        <div
          key={o.label}
          style={{
            ...rowIn(frame, i + 1),
            border: `1px solid ${o.correct ? p.fg : p.muted}`,
            background: o.correct ? p.fg : "transparent",
            padding: "24px 26px",
            marginBottom: 16,
            display: "flex",
            alignItems: "center",
            gap: 20,
          }}
        >
          <span
            style={{
              fontFamily: FONT_UI,
              fontSize: 24,
              fontWeight: 700,
              letterSpacing: 2,
              color: o.correct ? p.bg : p.muted,
              width: 32,
            }}
          >
            {String.fromCharCode(65 + i)}
          </span>
          <span
            style={{
              fontFamily: FONT_UI,
              fontSize: 30,
              fontWeight: o.correct ? 700 : 400,
              color: o.correct ? p.bg : p.fg,
            }}
          >
            {o.label}
          </span>
        </div>
      ))}
    </div>
  );
};

const HeartIcon: React.FC<{ color: string; filled: boolean; size?: number }> = ({
  color,
  filled,
  size = 44,
}) => (
  <svg viewBox="0 0 24 24" width={size} height={size} style={{ color }}>
    <path
      d="M12 21s-7.5-4.7-9.4-9A5.4 5.4 0 0 1 12 6.3a5.4 5.4 0 0 1 9.4 5.7C19.5 16.3 12 21 12 21z"
      fill={filled ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth={1.8}
    />
  </svg>
);

/** 05 — saved quotes plus the share affordance. */
const FavoritesVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  return (
    <div style={{ width: "100%" }}>
      {OTHERS.slice(0, 2).map((q, i) => (
        <Panel
          key={q.id}
          palette={palette}
          style={{
            ...rowIn(frame, i),
            padding: "26px 28px",
            marginBottom: 18,
            display: "flex",
            alignItems: "center",
            gap: 24,
          }}
        >
          <HeartIcon color={p.accent} filled />
          <div style={{ flex: 1 }}>
            <div
              style={{
                fontFamily: FONT_DISPLAY,
                fontSize: 36,
                lineHeight: 1.28,
                color: p.fg,
              }}
            >
              {q.text}
            </div>
            <div
              style={{
                fontFamily: FONT_UI,
                fontSize: 22,
                fontWeight: 600,
                letterSpacing: 1.8,
                color: p.muted,
                marginTop: 10,
                textTransform: "uppercase",
              }}
            >
              {q.author} · {formatYear(q.year)}
            </div>
          </div>
        </Panel>
      ))}
      <div
        style={{
          ...rowIn(frame, 2),
          display: "flex",
          gap: 14,
          marginTop: 16,
        }}
      >
        {["ALS BILD TEILEN", "PDF-EXPORT"].map((t) => (
          <span
            key={t}
            style={{
              fontFamily: FONT_UI,
              fontSize: 24,
              fontWeight: 700,
              letterSpacing: 2.4,
              color: p.onAccent,
              background: p.accent,
              padding: "16px 24px",
            }}
          >
            {t}
          </span>
        ))}
      </div>
    </div>
  );
};

/** 06 — home-screen widget tile plus a notification line. */
const WidgetVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  return (
    <div style={{ width: "100%" }}>
      <div style={{ ...rowIn(frame, 0), background: "#EDE8DF", padding: 0 }}>
        <div
          style={{
            background: p.accent,
            padding: "14px 24px",
            fontFamily: FONT_UI,
            fontSize: 21,
            fontWeight: 700,
            letterSpacing: 2.4,
            color: "#FFFFFF",
          }}
        >
          HEUTE · {HERO.year}
        </div>
        <div
          style={{
            padding: "30px 24px",
            fontFamily: FONT_DISPLAY,
            fontSize: 42,
            lineHeight: 1.26,
            color: "#1A1A1A",
          }}
        >
          {HERO.text}
        </div>
      </div>
      <div
        style={{
          ...rowIn(frame, 1),
          marginTop: 26,
          border: `1px solid ${palette === "paper" ? "#BBB5AB" : "rgba(237,232,223,0.3)"}`,
          padding: "24px 26px",
          display: "flex",
          alignItems: "center",
          gap: 22,
        }}
      >
        <div style={{ width: 14, height: 14, background: p.accent }} />
        <div>
          <div
            style={{
              fontFamily: FONT_UI,
              fontSize: 22,
              fontWeight: 700,
              letterSpacing: 2.4,
              color: p.muted,
            }}
          >
            ZITATE APP · JETZT
          </div>
          <div
            style={{
              fontFamily: FONT_UI,
              fontSize: 30,
              fontWeight: 500,
              color: p.fg,
              marginTop: 8,
            }}
          >
            Dein Zitat für heute ist da.
          </div>
        </div>
      </div>
    </div>
  );
};

/** 07 — interest chips and the parliament-style stance picker. */
const ProfileVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  const chips = [
    { label: "Geschichte", on: true },
    { label: "Politik", on: true },
    { label: "Philosophie", on: true },
    { label: "Ethik", on: false },
    { label: "Ökonomie", on: false },
  ];
  return (
    <div style={{ width: "100%" }}>
      <div
        style={{
          ...rowIn(frame, 0),
          fontFamily: FONT_UI,
          fontSize: 24,
          fontWeight: 700,
          letterSpacing: 3.4,
          color: p.muted,
          marginBottom: 22,
        }}
      >
        INTERESSEN
      </div>
      <div
        style={{
          ...rowIn(frame, 1),
          display: "flex",
          flexWrap: "wrap",
          gap: 14,
          marginBottom: 44,
        }}
      >
        {chips.map((c) => (
          <span
            key={c.label}
            style={{
              fontFamily: FONT_UI,
              fontSize: 27,
              fontWeight: c.on ? 700 : 500,
              letterSpacing: 1.6,
              padding: "16px 24px",
              border: `1px solid ${c.on ? p.accent : p.muted}`,
              background: c.on ? p.accent : "transparent",
              color: c.on ? "#FFFFFF" : p.muted,
            }}
          >
            {c.label}
          </span>
        ))}
      </div>

      <div
        style={{
          ...rowIn(frame, 2),
          fontFamily: FONT_UI,
          fontSize: 24,
          fontWeight: 700,
          letterSpacing: 3.4,
          color: p.muted,
          marginBottom: 22,
        }}
      >
        POLITISCHE HALTUNG
      </div>
      {/* Parliament arc, as in the settings picker */}
      <div
        style={{
          ...rowIn(frame, 3),
          display: "flex",
          alignItems: "flex-end",
          gap: 8,
          height: 120,
        }}
      >
        {[38, 52, 66, 82, 100, 112, 100, 82, 66, 52, 38].map((h, i) => (
          <div
            key={i}
            style={{
              flex: 1,
              height: h,
              background: i === 3 ? p.accent : p.muted,
              opacity: i === 3 ? 1 : 0.45,
            }}
          />
        ))}
      </div>
    </div>
  );
};

/** 08 — offline availability and cross-device sync. */
const SyncVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  const rows = [
    { k: "OFFLINE", v: "Alle Zitate liegen auf dem Gerät." },
    { k: "SYNC", v: "Favoriten und Fortschritt über alle Geräte." },
    { k: "STREAK", v: "Deine Serie zählt jeden Tag weiter." },
  ];
  return (
    <div style={{ width: "100%" }}>
      {rows.map((r, i) => (
        <div
          key={r.k}
          style={{
            ...rowIn(frame, i),
            display: "flex",
            gap: 30,
            alignItems: "baseline",
            padding: "26px 0",
            borderTop: `1px solid ${palette === "paper" ? "#BBB5AB" : "rgba(237,232,223,0.22)"}`,
          }}
        >
          <span
            style={{
              fontFamily: FONT_UI,
              fontSize: 24,
              fontWeight: 700,
              letterSpacing: 2.6,
              color: p.accent,
              width: 190,
              flexShrink: 0,
            }}
          >
            {r.k}
          </span>
          <span
            style={{
              fontFamily: FONT_DISPLAY,
              fontSize: 40,
              lineHeight: 1.3,
              color: p.fg,
            }}
          >
            {r.v}
          </span>
        </div>
      ))}
    </div>
  );
};

/** 09 — community submission going through review. */
const SubmitVisual: React.FC<VisualProps> = ({ frame, palette }) => {
  const p = PALETTES[palette];
  const steps = ["EINREICHEN", "PRÜFUNG", "VERÖFFENTLICHT"];
  return (
    <div style={{ width: "100%" }}>
      <div
        style={{
          ...rowIn(frame, 0),
          border: `1px solid ${p.fg}`,
          padding: "30px 28px",
          marginBottom: 34,
        }}
      >
        <div
          style={{
            fontFamily: FONT_UI,
            fontSize: 22,
            fontWeight: 700,
            letterSpacing: 2.6,
            color: p.muted,
          }}
        >
          ZITAT · QUELLE · JAHR
        </div>
        <div
          style={{
            fontFamily: FONT_DISPLAY,
            fontSize: 42,
            lineHeight: 1.3,
            color: p.fg,
            marginTop: 16,
          }}
        >
          Dein Fund landet in der Redaktion.
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        {steps.map((s, i) => (
          <React.Fragment key={s}>
            <span
              style={{
                ...rowIn(frame, i + 1),
                fontFamily: FONT_UI,
                fontSize: 23,
                fontWeight: 700,
                letterSpacing: 2,
                padding: "16px 20px",
                border: `1px solid ${p.fg}`,
                background: i === 2 ? p.fg : "transparent",
                color: i === 2 ? p.bg : p.fg,
                whiteSpace: "nowrap",
              }}
            >
              {s}
            </span>
            {i < steps.length - 1 && (
              <span
                style={{
                  ...rowIn(frame, i + 1),
                  fontFamily: FONT_UI,
                  fontSize: 30,
                  color: p.fg,
                }}
              >
                →
              </span>
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
};

const REGISTRY: Record<Feature["visual"], React.FC<VisualProps>> = {
  quote: QuoteVisual,
  einordnung: EinordnungVisual,
  atlas: AtlasVisual,
  quiz: QuizVisual,
  favorites: FavoritesVisual,
  widget: WidgetVisual,
  profile: ProfileVisual,
  sync: SyncVisual,
  submit: SubmitVisual,
};

export const Visual: React.FC<{
  kind: Feature["visual"];
  frame: number;
  palette: Palette;
}> = ({ kind, frame, palette }) => {
  const Component = REGISTRY[kind];
  return <Component frame={frame} palette={palette} />;
};
