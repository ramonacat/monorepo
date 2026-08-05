import { globalStyle } from "@vanilla-extract/css";
import { vars } from "../theme-contract.css";

globalStyle("*, *::before, *::after", {
  boxSizing: "border-box",
  margin: 0,
  padding: 0,
});

globalStyle("body", {
  backgroundColor: vars.defaults.colors.background,

  lineHeight: 1.5,

  color: vars.text.colors.normal,

  fontFamily: vars.text.fonts.families.default,
  fontSize: vars.text.sizes.root,
  fontWeight: vars.text.fonts.weights.normal,
});

globalStyle("a", {
  color: vars.link.colors.normal,
});

globalStyle("a:hover", {
  color: vars.link.colors.hover,
});

globalStyle("h1,h2,h3,h4,h5,h6", {
  color: vars.text.colors.header,
  fontWeight: vars.text.fonts.weights.bold,
  fontVariantLigatures: "none",
});

globalStyle("h1", { fontSize: vars.text.sizes.h1 });
globalStyle("h2", { fontSize: vars.text.sizes.h2 });
globalStyle("h3", { fontSize: vars.text.sizes.h3 });
globalStyle("h4", { fontSize: vars.text.sizes.h4 });
globalStyle("h5", { fontSize: vars.text.sizes.h5 });
globalStyle("h6", { fontSize: vars.text.sizes.h6 });

globalStyle(":focus-visible", {
  outline: 0,
  border: 0,
});

globalStyle("input, button, textarea, select, option", {
  font: "inherit",
});

globalStyle("pre, code", {
  fontFamily: vars.text.fonts.families.monospace,
});

globalStyle("ul", {
  listStylePosition: "inside",
});

globalStyle("ul ul", {
  marginLeft: vars.defaults.spacings.l,
});
