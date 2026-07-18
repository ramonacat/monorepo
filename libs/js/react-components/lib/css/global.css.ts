import { globalStyle } from "@vanilla-extract/css";
import { vars } from "../theme-contract.css";
import { privateVars } from "./theme-contract-private.css";

globalStyle("*, *::after, *::before", {
  boxSizing: "border-box",
  margin: 0,
});

globalStyle("body", {
  backgroundColor: vars.colors.background,

  lineHeight: 1.5,

  color: vars.colors.text,

  fontFamily: vars.fonts.families.default,
  fontSize: privateVars.sizes.font.root,
  fontWeight: vars.fonts.weights.normal,
});

globalStyle("h1,h2,h3,h4,h5,h6", {
  color: vars.colors.textHeader,
  fontWeight: vars.fonts.weights.bold,
  fontVariantLigatures: "none",
});

globalStyle("h1", { fontSize: privateVars.sizes.font.h1 });
globalStyle("h2", { fontSize: privateVars.sizes.font.h2 });
globalStyle("h3", { fontSize: privateVars.sizes.font.h3 });
globalStyle("h4", { fontSize: privateVars.sizes.font.h4 });
globalStyle("h5", { fontSize: privateVars.sizes.font.h5 });
globalStyle("h6", { fontSize: privateVars.sizes.font.h6 });

globalStyle(":focus-visible", {
  outline: 0,
  border: 0,
});

globalStyle("input, button, textarea, select, option", {
  font: "inherit",
});

globalStyle("pre, code", {
  fontFamily: vars.fonts.families.monospace,
});

globalStyle("ul", {
  listStylePosition: "inside",
});

globalStyle("ul ul", {
  marginLeft: privateVars.spacings.l,
});
