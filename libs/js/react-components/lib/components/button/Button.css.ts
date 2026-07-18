import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";
import { privateVars } from "../../css/theme-contract-private.css";

export const button = style({
  display: "flex",
  alignContent: "center",
  alignItems: "center",
  border: "none",
  backgroundColor: vars.colors.button,
  padding: `${privateVars.spacings.l}`,
  textDecoration: "none",
  color: vars.colors.text,

  ":hover": {
    backgroundColor: vars.colors.buttonHover,
    cursor: "pointer",
  },
});

export const buttonIconOnly = style([
  button,
  {
    padding: privateVars.spacings.l,
  },
]);

export const buttonActive = style({
  backgroundColor: vars.colors.buttonActive,
});

export const text = style({
  display: "table-cell",
  verticalAlign: "middle",
});

export const submit = style({
  justifyContent: "center",
  width: "100%",
  fontSize: privateVars.sizes.font.attention,
});

export const contentsContainer = style({
  marginLeft: privateVars.spacings.m,
});
