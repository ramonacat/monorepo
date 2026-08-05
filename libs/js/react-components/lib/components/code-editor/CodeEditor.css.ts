import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";

export const container = style({
  contain: "layout",
});

export const codeEditor = style({
  width: "100%",
});

export const status = style({
  position: "absolute",
  right: vars.defaults.spacings.l,
  bottom: vars.defaults.spacings.l,
  transition: `opacity ${vars.defaults.animation.duration.m} ${vars.defaults.animation.timingFunction.replace}`,
  opacity: 0,
  width: vars.icon.sizes.xxl,
  height: vars.icon.sizes.xxl,
});

export const success = style({
  color: vars.defaults.colors.success,
});

export const error = style({
  color: vars.defaults.colors.error,
});

export const show = style({
  // eslint-disable-next-line vanilla-extract/prefer-theme-tokens
  opacity: 1,
});
