import { style } from "@vanilla-extract/css";
import { vars } from "../../css/theme-contract.css";

export const table = style({
  display: "table",
  border: `${vars.sizes.border.xs} solid ${vars.colors.tableBorder}`,
  width: "100%",
  borderCollapse: "collapse",
});

export const thead = style({
  backgroundColor: vars.colors.backgroundSecondary,
});

export const td = style({
  border: `${vars.sizes.border.xs} solid ${vars.colors.tableBorder}`,
  padding: vars.spacings.m,
});
