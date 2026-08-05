import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";

export const section = style({
  marginBottom: vars.defaults.spacings.l,
});

export const contents = style({
  padding: `0 ${vars.defaults.spacings.l}`,
});

export const sectionHeader = style({
  display: "flex",
  marginBottom: vars.defaults.spacings.l,
  backgroundColor: vars.defaults.colors.backgroundSecondary,
  width: "100%",
  selectors: {
    ["&:has(h1)"]: {
      marginBottom: 0,
      borderBottom: `${vars.defaults.sizes.border.s} solid ${vars.defaults.colors.brand}`,
    },
  },
});

export const sectionHeaderTopNavigation = style({
  padding: `0rem ${vars.defaults.spacings.l}`,
});

export const heading = style({
  margin: `0 ${vars.defaults.spacings.l}`,
  padding: `${vars.defaults.spacings.l} 0`,
});

export const headerNavigation = style({
  display: "flex",
  gap: vars.defaults.spacings.s,
  marginLeft: "auto",
});

export const editableHeading = style({
  cursor: "pointer",
});

export const editIcon = style({
  fontSize: vars.text.sizes.primary,
});

export const editableHeadingInput = style({
  fontWeight: vars.text.fonts.weights.bold,
});

export const editableH1 = style({ fontSize: vars.text.sizes.h1 });
export const editableH2 = style({ fontSize: vars.text.sizes.h2 });
export const editableH3 = style({ fontSize: vars.text.sizes.h3 });
export const editableH4 = style({ fontSize: vars.text.sizes.h4 });
export const editableH5 = style({ fontSize: vars.text.sizes.h5 });
export const editableH6 = style({ fontSize: vars.text.sizes.h6 });
