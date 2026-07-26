import "./index.css";
import "./promo/fonts";
import { Composition } from "remotion";
import { Promo, PROMO_DURATION } from "./promo/Promo";
import { VIDEO } from "./promo/theme";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Werbeclip"
        component={Promo}
        durationInFrames={PROMO_DURATION}
        fps={VIDEO.fps}
        width={VIDEO.width}
        height={VIDEO.height}
      />
    </>
  );
};
