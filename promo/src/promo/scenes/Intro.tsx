import React from "react";
import { AbsoluteFill, Easing, Interactive, interpolate, useCurrentFrame } from "remotion";
import { FEATURES } from "../features";
import { QUOTE_COUNT } from "../quotes";
import { COLORS, FONT_DISPLAY, FONT_UI } from "../theme";

const EASE_OUT = Easing.bezier(0.16, 1, 0.3, 1);

/** Title card: names the product and the promise, then gets out of the way. */
export const Intro: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill style={{ background: COLORS.ink }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          paddingInline: 96,
        }}
      >
        <div style={{ overflow: "hidden" }}>
          <Interactive.Div
            name="Product name"
            style={{
              fontFamily: FONT_UI,
              fontSize: 30,
              fontWeight: 700,
              letterSpacing: 8,
              color: COLORS.rule,
              translate:
                "0px " +
                interpolate(frame, [4, 24], [110, 0], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                  easing: EASE_OUT,
                }).toFixed(2) +
                "%",
            }}
          >
            QUOTIDIAN · ZITATE-APP
          </Interactive.Div>
        </div>

        <div style={{ overflow: "hidden", marginTop: 34 }}>
          <Interactive.Div
            name="Headline"
            style={{
              fontFamily: FONT_DISPLAY,
              fontSize: 132,
              fontWeight: 700,
              letterSpacing: -4,
              lineHeight: 0.98,
              color: COLORS.paper,
              translate:
                "0px " +
                interpolate(frame, [10, 34], [110, 0], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                  easing: EASE_OUT,
                }).toFixed(2) +
                "%",
            }}
          >
            {QUOTE_COUNT} Zitate.
          </Interactive.Div>
        </div>

        <div style={{ overflow: "hidden", marginTop: 6 }}>
          <Interactive.Div
            name="Headline 2"
            style={{
              fontFamily: FONT_DISPLAY,
              fontSize: 132,
              fontWeight: 700,
              fontStyle: "italic",
              letterSpacing: -4,
              lineHeight: 0.98,
              color: COLORS.red,
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
            Alle belegt.
          </Interactive.Div>
        </div>

        {/* Thick red rule wiping in from the left */}
        <Interactive.Div
          name="Red rule"
          style={{
            height: 14,
            width: "100%",
            background: COLORS.red,
            marginTop: 96,
            transformOrigin: "left center",
            scale:
              interpolate(frame, [24, 46], [0, 1], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                easing: EASE_OUT,
              }).toFixed(3) + " 1",
          }}
        />

        <Interactive.Div
          name="Feature count"
          style={{
            marginTop: 40,
            fontFamily: FONT_UI,
            fontSize: 34,
            fontWeight: 600,
            letterSpacing: 4,
            color: COLORS.paper,
            opacity: interpolate(frame, [34, 52], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          {FEATURES.length} FUNKTIONEN IM ÜBERBLICK
        </Interactive.Div>
      </div>
    </AbsoluteFill>
  );
};
