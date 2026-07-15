import { style } from "@vanilla-extract/css";
import { vars } from "../../css/theme-contract.css";

export const row = style({
  display: "flex",
  alignItems: "center",
  margin: `${vars.spacings.l} 0`,
  width: "100%",
});

export const label = style({
  width: vars.sizes.form.label.width,
});

export const inputWrapper = style({
  display: "flex",
  alignItems: "stretch",
  width: vars.sizes.form.input.width,
});

export const attachment = style({
  display: "flex",
  alignItems: "center",
  border: `${vars.sizes.border.xs} solid ${vars.colors.inputBorder}`,
  padding: `0 ${vars.spacings.l}`,
});

export const input = style({
  flexGrow: "1",
  border: `${vars.sizes.border.xs} solid ${vars.colors.inputBorder}`,
  backgroundColor: vars.colors.inputBackground,
  padding: vars.spacings.m,
  minWidth: "0",
  color: `${vars.colors.text}`,
  ":focus-visible": {
    boxShadow: vars.shadows.highlight,
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
