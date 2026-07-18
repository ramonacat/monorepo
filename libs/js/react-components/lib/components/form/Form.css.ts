import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";
import { privateVars } from "../../css/theme-contract-private.css";

export const row = style({
  display: "flex",
  alignItems: "center",
  margin: `${privateVars.spacings.l} 0`,
  width: "100%",
});

export const label = style({
  width: privateVars.sizes.form.label.width,
});

export const inputWrapper = style({
  display: "flex",
  alignItems: "stretch",
  width: privateVars.sizes.form.input.width,
});

export const attachment = style({
  display: "flex",
  alignItems: "center",
  border: `${privateVars.sizes.border.xs} solid ${vars.colors.inputBorder}`,
  padding: `0 ${privateVars.spacings.l}`,
});

export const input = style({
  flexGrow: "1",
  border: `${privateVars.sizes.border.xs} solid ${vars.colors.inputBorder}`,
  backgroundColor: vars.colors.inputBackground,
  padding: privateVars.spacings.m,
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
