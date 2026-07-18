import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";
import { privateVars } from "../../css/theme-contract-private.css";

export const section = style({
  marginBottom: privateVars.spacings.l,
});

export const contents = style({
  padding: `0 ${privateVars.spacings.l}`,
});

export const sectionHeader = style({
  display: "flex",
  marginBottom: privateVars.spacings.l,
  backgroundColor: vars.colors.backgroundSecondary,
  width: "100%",
  selectors: {
    ["&:has(h1)"]: {
      marginBottom: 0,
      borderBottom: `${privateVars.sizes.border.s} solid ${vars.colors.brand}`,
    },
  },
});

export const sectionHeaderTopNavigation = style({
  padding: `0rem ${privateVars.spacings.l}`,
});

export const heading = style({
  margin: `0 ${privateVars.spacings.l}`,
  padding: `${privateVars.spacings.l} 0`,
});

export const headerNavigation = style({
  display: "flex",
  gap: privateVars.spacings.s,
  marginLeft: "auto",
});

export const editableHeading = style({
  cursor: "pointer",
});

export const editIcon = style({
  fontSize: privateVars.sizes.font.primary,
});

export const editableHeadingInput = style({
  fontWeight: vars.fonts.weights.bold,
});

export const editableH1 = style({ fontSize: privateVars.sizes.font.h1 });
export const editableH2 = style({ fontSize: privateVars.sizes.font.h2 });
export const editableH3 = style({ fontSize: privateVars.sizes.font.h3 });
export const editableH4 = style({ fontSize: privateVars.sizes.font.h4 });
export const editableH5 = style({ fontSize: privateVars.sizes.font.h5 });
export const editableH6 = style({ fontSize: privateVars.sizes.font.h6 });
