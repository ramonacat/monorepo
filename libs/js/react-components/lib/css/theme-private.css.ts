import { createTheme } from "@vanilla-extract/css";
import { privateVars } from "./theme-contract-private.css";

export const themePrivate = createTheme(privateVars, {
  spacings: {
    s: "0.25rem",
    m: "0.5rem",
    l: "1rem",
  },
  sizes: {
    form: {
      label: { width: "200px" },
      input: { width: "300px" },
    },
    border: { xs: "1px", s: "2px" },
    icon: { xxl: "2rem" },
    font: {
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
  },
  animation: {
    duration: { m: "500ms" },
    timingFunction: {
      replace: "ease-in-out",
    },
  },
});
