import { style } from "@vanilla-extract/css";
import { vars } from "../../css/theme-contract.css";

export const container = style({
  contain: "layout",
});

export const codeEditor = style({
  width: "100%",
});

export const status = style({
  position: "absolute",
  right: vars.spacings.l,
  bottom: vars.spacings.l,
  transition: `opacity ${vars.animation.duration.m} ${vars.animation.timingFunction.replace}`,
  opacity: 0,
  width: vars.sizes.icon.xxl,
  height: vars.sizes.icon.xxl,
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
