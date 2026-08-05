import { vars } from "./theme-contract.css";
import { createTheme } from "@vanilla-extract/css";
import fonts from "./css/fonts";

export const theme = createTheme(vars, {
  defaults: {
    colors: {
      background: "#111",
      backgroundSecondary: `oklab(from ${vars.defaults.colors.background} calc(l + 0.04) a b)`,
      brand: "#ff1885",

      // TODO nicer colors?
      error: "red",
      success: "green",
    },
    shadows: {
      highlight: `0 0 3px 2px ${vars.defaults.colors.brand}`,
    },
    sizes: {
      border: { xs: "1px", s: "2px" },
    },
    spacings: {
      s: "0.25rem",
      m: "0.5rem",
      l: "1rem",
    },
    animation: {
      duration: { m: "500ms" },
      timingFunction: {
        replace: "ease-in-out",
      },
    },
  },
  icon: { sizes: { xxl: "2rem" } },
  button: {
    colors: {
      normal: `oklab(from ${vars.defaults.colors.background} calc(l + 0.1) a b)`,
      hover: `oklab(from ${vars.button.colors.normal} calc(l + 0.1) a b)`,
      active: vars.defaults.colors.background,
    },
  },
  input: {
    colors: {
      border: `oklab(from ${vars.defaults.colors.brand} calc(l + 0.2) a b)`,
      background: vars.defaults.colors.backgroundSecondary,
    },
    sizes: {
      width: "300px",
      border: vars.defaults.sizes.border.xs,
    },
  },
  label: {
    sizes: { width: "200px" },
  },
  text: {
    colors: {
      normal: "#eee",
      header: vars.text.colors.normal,
    },
    sizes: {
      root: "16px",
      attention: "1.5rem",
      primary: "1rem",
      h1: "2.55rem",
      h2: "2.3rem",
      h3: "2rem",
      h4: "1.6rem",
      h5: "1.5rem",
      h6: "1.4rem",
    },
    fonts,
  },
  link: {
    colors: {
      normal: vars.text.colors.normal,
      hover: "#ffffff",
    },
  },
  table: {
    colors: {
      border: `oklab(from ${vars.defaults.colors.brand} calc(l + 0.1) a b)`,
    },
  },
  modal: {
    backdrop: {
      color: "rgba(1,1,1,0.5)",
      filter: "blur(3px)",
    },
  },
});
