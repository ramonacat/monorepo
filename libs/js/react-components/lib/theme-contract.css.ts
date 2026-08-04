import { createThemeContract } from "@vanilla-extract/css";

// TODO this needs more thorough cleanup
export const vars = createThemeContract({
  colors: {
    background: "",
    backgroundSecondary: "",
    brand: "",
    button: "",
    buttonActive: "",
    buttonHover: "",
    error: "",
    foreground: "",
    inputBackground: "",
    inputBorder: "",
    linkHover: "",
    success: "",
    tableBorder: "",
    text: "",
    textHeader: "",
  },
  fonts: {
    weights: {
      normal: "",
      bold: "",
    },
    families: {
      default: "",
      monospace: "",
    },
    sizes: {
      root: "",
    },
  },
  modal: {
    backdrop: {
      color: "",
      filter: "",
    },
  },
  shadows: {
    highlight: "",
  },
});
