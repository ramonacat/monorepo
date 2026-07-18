import { createThemeContract } from "@vanilla-extract/css";

// TODO this needs more thorough cleanup
export const vars = createThemeContract({
  colors: {
    brand: "",
    tableBorder: "",
    backgroundSecondary: "",
    background: "",
    text: "",
    textHeader: "",
    inputBorder: "",
    inputBackground: "",
    success: "",
    error: "",
    button: "",
    buttonActive: "",
    buttonHover: "",
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
