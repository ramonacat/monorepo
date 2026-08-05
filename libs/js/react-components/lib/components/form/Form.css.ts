import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";

export const row = style({
  display: "flex",
  alignItems: "center",
  margin: `${vars.defaults.spacings.l} 0`,
  width: "100%",

  "@media": {
    "(max-width: 500px)": {
      flexDirection: "column",
      alignItems: "flex-start",
    },
  },
});

export const label = style({
  width: vars.label.sizes.width,
});

export const inputWrapper = style({
  display: "flex",
  alignItems: "stretch",
  width: vars.input.sizes.width,
});

export const attachment = style({
  display: "flex",
  alignItems: "center",
  border: `${vars.input.sizes.border} solid ${vars.input.colors.border}`,
  padding: `0 ${vars.defaults.spacings.l}`,
});

export const input = style({
  flexGrow: "1",
  border: `${vars.input.sizes.border} solid ${vars.input.colors.border}`,
  backgroundColor: vars.input.colors.background,
  padding: vars.defaults.spacings.m,
  minWidth: "0",
  color: `${vars.text.colors.normal}`,
  ":focus-visible": {
    boxShadow: vars.defaults.shadows.highlight,
  },
  selectors: {
    [`&:has(+ ${attachment})`]: {
      borderRight: 0,
    },
    ['&[type="number"]']: {
      appearance: "textfield",
      textAlign: "right",
    },
  },
});
