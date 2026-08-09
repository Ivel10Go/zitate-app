import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  Interactive,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { QUOTE_COUNT } from "../quotes";
import { COLORS, FONT_DISPLAY, FONT_UI } from "../theme";

const EASE_OUT = Easing.bezier(0.16, 1, 0.3, 1);

/**
 * Closing panel. Wipes up like every feature scene so the ending belongs to
 * the same rhythm, then lands on paper — the app's own palette.
 */
export const Cta: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill
      style={{
        background: COLORS.paper,
        translate:
          "0px " +
          interpolate(frame, [0, 13], [100, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: EASE_OUT,
          }).toFixed(2) +
          "%",
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 44,
          paddingInline: 96,
        }}
      >
        <Interactive.Div
          name="Logo"
          style={{
            border: `1px solid ${COLORS.ink}`,
            padding: 16,
            opacity: interpolate(frame, [10, 28], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            scale: interpolate(frame, [10, 34], [0.9, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: EASE_OUT,
            }),
          }}
        >
          <Img
            src={staticFile("logo.png")}
            style={{ width: 280, height: 280, display: "block" }}
          />
        </Interactive.Div>

        <div style={{ overflow: "hidden" }}>
          <Interactive.Div
            name="Claim"
            style={{
              fontFamily: FONT_DISPLAY,
              fontSize: 86,
              fontWeight: 700,
              letterSpacing: -2.4,
              lineHeight: 1.06,
              color: COLORS.ink,
              textAlign: "center",
              translate:
                "0px " +
                interpolate(frame, [18, 42], [110, 0], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                  easing: EASE_OUT,
                }).toFixed(2) +
                "%",
            }}
          >
            Zitate, die wirklich
            <br />
            gesagt wurden.
          </Interactive.Div>
        </div>

        <Interactive.Div
          name="Store block"
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 26,
            opacity: interpolate(frame, [34, 52], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          <div
            style={{
              fontFamily: FONT_UI,
              fontSize: 28,
              fontWeight: 600,
              letterSpacing: 3,
              color: COLORS.inkLight,
              textAlign: "center",
            }}
          >
            {QUOTE_COUNT} BELEGTE ZITATE · OFFLINE · KOSTENLOS STARTEN
          </div>
          <div
            style={{
              fontFamily: FONT_UI,
              fontSize: 36,
              fontWeight: 700,
              letterSpacing: 2.4,
              color: COLORS.onRed,
              background: COLORS.red,
              padding: "24px 52px",
            }}
          >
            JETZT BEI GOOGLE PLAY
          </div>
        </Interactive.Div>
      </div>
    </AbsoluteFill>
  );
};
