import { style } from "@vanilla-extract/css";
import { vars } from "../../css/theme-contract.css";

export const section = style({
  marginBottom: vars.spacings.l,
});

export const contents = style({
  padding: `0 ${vars.spacings.l}`,
});

export const sectionHeader = style({
  display: "flex",
  marginBottom: vars.spacings.l,
  backgroundColor: vars.colors.backgroundSecondary,
  width: "100%",
  selectors: {
    ["&:has(h1)"]: {
      marginBottom: 0,
      borderBottom: `${vars.sizes.border.s} solid ${vars.colors.brand}`,
    },
  },
});

export const sectionHeaderTopNavigation = style({
  padding: `0rem ${vars.spacings.l}`,
});

export const heading = style({
  margin: `0 ${vars.spacings.l}`,
  padding: `${vars.spacings.l} 0`,
});

export const headerNavigation = style({
  display: "flex",
  gap: vars.spacings.s,
  marginLeft: "auto",
});

export const editableHeading = style({
  cursor: "pointer",
});

export const editIcon = style({
  fontSize: vars.sizes.font.primary,
});

export const editableHeadingInput = style({
  fontWeight: vars.fonts.weights.bold,
});

export const editableH1 = style({ fontSize: vars.sizes.font.h1 });
export const editableH2 = style({ fontSize: vars.sizes.font.h2 });
export const editableH3 = style({ fontSize: vars.sizes.font.h3 });
export const editableH4 = style({ fontSize: vars.sizes.font.h4 });
export const editableH5 = style({ fontSize: vars.sizes.font.h5 });
export const editableH6 = style({ fontSize: vars.sizes.font.h6 });
