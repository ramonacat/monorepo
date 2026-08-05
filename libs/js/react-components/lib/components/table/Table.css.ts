import { style } from "@vanilla-extract/css";
import { vars } from "../../theme-contract.css";

export const table = style({
  display: "table",
  border: `${vars.defaults.sizes.border.xs} solid ${vars.table.colors.border}`,
  width: "100%",
  borderCollapse: "collapse",
});

export const thead = style({
  backgroundColor: vars.defaults.colors.backgroundSecondary,
});

export const td = style({
  border: `${vars.defaults.sizes.border.xs} solid ${vars.table.colors.border}`,
  padding: vars.defaults.spacings.m,
});
