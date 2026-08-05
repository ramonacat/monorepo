import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";

export const button = style({
  display: "flex",
  alignContent: "center",
  alignItems: "center",
  border: "none",
  backgroundColor: vars.button.colors.normal,
  padding: `${vars.defaults.spacings.l}`,
  textDecoration: "none",
  color: vars.text.colors.normal,

  ":hover": {
    backgroundColor: vars.button.colors.hover,
    cursor: "pointer",
  },
});

export const buttonIconOnly = style([
  button,
  {
    padding: vars.defaults.spacings.l,
  },
]);

export const buttonActive = style({
  backgroundColor: vars.button.colors.active,
});

export const text = style({
  display: "table-cell",
  verticalAlign: "middle",
});

export const submit = style({
  justifyContent: "center",
  width: "100%",
  fontSize: vars.text.sizes.attention,
});

export const contentsContainer = style({
  margin: "0 auto",
});

export const contentsContainerWithIcon = style({
  marginLeft: vars.defaults.spacings.m,
});
