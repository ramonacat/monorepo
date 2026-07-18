import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";
import { privateVars } from "../../css/theme-contract-private.css";

export const container = style({
  contain: "layout",
});

export const codeEditor = style({
  width: "100%",
});

export const status = style({
  position: "absolute",
  right: privateVars.spacings.l,
  bottom: privateVars.spacings.l,
  transition: `opacity ${privateVars.animation.duration.m} ${privateVars.animation.timingFunction.replace}`,
  opacity: 0,
  width: privateVars.sizes.icon.xxl,
  height: privateVars.sizes.icon.xxl,
});

export const success = style({
  color: vars.colors.success,
});

export const error = style({
  color: vars.colors.error,
});

export const show = style({
  // eslint-disable-next-line vanilla-extract/prefer-theme-tokens
  opacity: 1,
});
