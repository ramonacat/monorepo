import { globalStyle, style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";
import { privateVars } from "../../css/theme-contract-private.css";

export const closeIcon = style({
  width: privateVars.sizes.icon.xxl,
  height: privateVars.sizes.icon.xxl,
});

export const dialog = style({
  margin: "auto",
  border: "0",
  backgroundColor: vars.colors.background,
  padding: "0",
  width: "80%",
  height: "80%",
  color: vars.colors.text,
  "::backdrop": {
    backgroundColor: vars.modal.backdrop.color,
  },
  selectors: {
    ["&[open]"]: {
      display: "grid",
    },
  },
});

globalStyle(`body:has(${dialog}[open])`, {
  filter: vars.modal.backdrop.filter,
});

export const section = style({
  display: "flex",
  flexDirection: "column",
});

export const sectionContents = style({
  display: "grid",
  flexGrow: "1",
  alignItems: "center",
  justifyItems: "center",
});
