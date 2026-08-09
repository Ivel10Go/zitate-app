import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { FEATURES } from "./features";
import { Cta } from "./scenes/Cta";
import { FeatureScene, WIPE } from "./scenes/FeatureScene";
import { Intro } from "./scenes/Intro";
import { COLORS } from "./theme";

/** Timeline constants (30 fps). */
const INTRO = 62;
/** Frames per feature — deliberately short; the cut rhythm carries the clip. */
const PER_FEATURE = 62;
const CTA = 104;

export const FEATURES_START = INTRO;
export const CTA_START = INTRO + FEATURES.length * PER_FEATURE;
export const PROMO_DURATION = CTA_START + CTA;

/**
 * A feature showcase, not a walkthrough: every scene names one capability and
 * shows a real UI fragment of it. No device frame and no simulated taps — the
 * point is what the app does, not how it is operated.
 *
 * Scenes overlap by WIPE frames so each incoming panel slides up over the
 * previous one. Later Sequences paint on top, so the overlap is the transition.
 */
export const Promo: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: COLORS.ink }}>
      <Sequence name="Intro" durationInFrames={INTRO + WIPE}>
        <Intro />
      </Sequence>

      {FEATURES.map((feature, i) => (
        <Sequence
          key={feature.name}
          name={`${String(i + 1).padStart(2, "0")} ${feature.name}`}
          from={FEATURES_START + i * PER_FEATURE}
          durationInFrames={PER_FEATURE + WIPE}
        >
          <FeatureScene
            feature={feature}
            index={i}
            total={FEATURES.length}
          />
        </Sequence>
      ))}

      <Sequence name="Abschluss" from={CTA_START} durationInFrames={CTA}>
        <Cta />
      </Sequence>
    </AbsoluteFill>
  );
};
