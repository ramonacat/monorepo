import { vars } from "./theme-contract.css";
import { createTheme } from "@vanilla-extract/css";

export const theme = createTheme(vars, {
  colors: {
    brand: "#ff1885",
    foreground: "#eee",

    // TODO nicer colors?
    success: "green",
    error: "red",

    text: vars.colors.foreground,
    textHeader: vars.colors.text,

    background: "#111",
    backgroundSecondary: `oklab(from ${vars.colors.background} calc(l + 0.04) a b)`,

    button: `oklab(from ${vars.colors.background} calc(l + 0.1) a b)`,
    buttonHover: `oklab(from ${vars.colors.button} calc(l + 0.1) a b)`,
    buttonActive: vars.colors.background,

    inputBorder: `oklab(from ${vars.colors.brand} calc(l + 0.2) a b)`,
    inputBackground: vars.colors.backgroundSecondary,

    tableBorder: `oklab(from ${vars.colors.brand} calc(l + 0.1) a b)`,
    linkHover: "#ffffff",
  },
  fonts: {
    families: {
      default: '"Raleway Variable", sans-serif',
      monospace: "Iosevka, monospace",
    },
    weights: { normal: "300", bold: "750" },
    sizes: {
      root: "16px",
    },
  },
  shadows: { highlight: `0 0 3px 2px ${vars.colors.brand}` },
  modal: {
    backdrop: {
      color: "rgba(1,1,1,0.5)",
      filter: "blur(3px)",
    },
  },
});
