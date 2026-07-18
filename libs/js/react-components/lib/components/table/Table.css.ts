import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";
import { privateVars } from "../../css/theme-contract-private.css";

export const table = style({
  display: "table",
  border: `${privateVars.sizes.border.xs} solid ${vars.colors.tableBorder}`,
  width: "100%",
  borderCollapse: "collapse",
});

export const thead = style({
  backgroundColor: vars.colors.backgroundSecondary,
});

export const td = style({
  border: `${privateVars.sizes.border.xs} solid ${vars.colors.tableBorder}`,
  padding: privateVars.spacings.m,
});
