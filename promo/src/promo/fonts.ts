import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";
import { FONT_DISPLAY, FONT_UI } from "./theme";

type FaceSpec = {
  family: string;
  file: string;
  weight: string;
  style?: "normal" | "italic";
};

/**
 * The app ships these exact TTFs in assets/fonts, so the promo uses the same
 * files rather than a Google Fonts fetch — identical rendering, and no network
 * dependency at render time.
 */
const FACES: FaceSpec[] = [
  { family: FONT_DISPLAY, file: "PlayfairDisplay-Regular.ttf", weight: "400" },
  { family: FONT_DISPLAY, file: "PlayfairDisplay-Bold.ttf", weight: "700" },
  {
    family: FONT_DISPLAY,
    file: "PlayfairDisplay-Italic.ttf",
    weight: "400",
    style: "italic",
  },
  { family: FONT_UI, file: "IBMPlexSans-Regular.ttf", weight: "400" },
  { family: FONT_UI, file: "IBMPlexSans-Medium.ttf", weight: "500" },
  { family: FONT_UI, file: "IBMPlexSans-SemiBold.ttf", weight: "600" },
  { family: FONT_UI, file: "IBMPlexSans-Bold.ttf", weight: "700" },
];

// Not awaited on purpose: loadFont() brackets itself in delayRender() /
// continueRender(), so both Studio and the renderer already block on every
// face before painting a frame.
for (const face of FACES) {
  void loadFont({
    family: face.family,
    url: staticFile(`fonts/${face.file}`),
    weight: face.weight,
    style: face.style ?? "normal",
  });
}
