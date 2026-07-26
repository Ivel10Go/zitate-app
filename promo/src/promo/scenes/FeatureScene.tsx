import React from "react";
import { AbsoluteFill, Easing, Interactive, interpolate, useCurrentFrame } from "remotion";
import { PALETTES, type Feature } from "../features";
import { Visual } from "../visuals";
import { FONT_DISPLAY, FONT_UI } from "../theme";

const EASE_OUT = Easing.bezier(0.16, 1, 0.3, 1);

/** Frames the incoming panel takes to cover the previous scene. */
export const WIPE = 13;

/**
 * One feature per full-bleed panel. The panel itself slides up over the
 * outgoing scene — an opaque wipe, so nothing ever cross-fades into
 * double-exposed text.
 */
export const FeatureScene: React.FC<{
  feature: Feature;
  index: number;
  total: number;
}> = ({ feature, index, total }) => {
  const frame = useCurrentFrame();
  const p = PALETTES[feature.palette];

  return (
    <AbsoluteFill
      style={{
        background: p.bg,
        translate:
          "0px " +
          interpolate(frame, [0, WIPE], [100, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: EASE_OUT,
          }).toFixed(2) +
          "%",
      }}
    >
      {/* Oversized index digit, purely graphic */}
      <div
        style={{
          position: "absolute",
          right: -40,
          top: 150,
          fontFamily: FONT_DISPLAY,
          fontSize: 460,
          fontWeight: 700,
          lineHeight: 1,
          color: "transparent",
          WebkitTextStroke: `2px ${p.accent}`,
          opacity: 0.16,
        }}
      >
        {String(index + 1).padStart(2, "0")}
      </div>

      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          paddingInline: 96,
          paddingBottom: 40,
        }}
      >
        {/* Counter */}
        <Interactive.Div
          name="Counter"
          style={{
            display: "flex",
            alignItems: "center",
            gap: 20,
            opacity: interpolate(frame, [8, 22], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          <div style={{ width: 56, height: 4, background: p.accent }} />
          <span
            style={{
              fontFamily: FONT_UI,
              fontSize: 26,
              fontWeight: 700,
              letterSpacing: 4,
              color: p.muted,
            }}
          >
            {String(index + 1).padStart(2, "0")} / {String(total).padStart(2, "0")}
          </span>
        </Interactive.Div>

        {/* Feature name — masked reveal from below */}
        <div style={{ overflow: "hidden", marginTop: 26 }}>
          <Interactive.Div
            name="Feature name"
            style={{
              fontFamily: FONT_DISPLAY,
              fontSize: 118,
              fontWeight: 700,
              letterSpacing: -3,
              lineHeight: 1.02,
              color: p.fg,
              translate:
                "0px " +
                interpolate(frame, [6, 26], [120, 0], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                  easing: EASE_OUT,
                }).toFixed(2) +
                "%",
            }}
          >
            {feature.name}
          </Interactive.Div>
        </div>

        <Interactive.Div
          name="Description"
          style={{
            fontFamily: FONT_UI,
            fontSize: 38,
            fontWeight: 400,
            lineHeight: 1.38,
            color: p.muted,
            marginTop: 22,
            maxWidth: 820,
            opacity: interpolate(frame, [16, 32], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          {feature.description}
        </Interactive.Div>

        {/* Supporting UI fragment */}
        <div style={{ marginTop: 62 }}>
          <Visual
            kind={feature.visual}
            frame={frame}
            palette={feature.palette}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};
