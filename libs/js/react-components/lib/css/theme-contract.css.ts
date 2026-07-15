import { createThemeContract } from "@vanilla-extract/css";

export const vars = createThemeContract({
  sizes: {
    border: {
      xs: "",
      s: "",
    },
    font: {
      primary: "",
      h1: "",
      h2: "",
      h3: "",
      h4: "",
      h5: "",
      h6: "",
      attention: "",
    },
    icon: {
      xxl: "",
    },
    form: {
      input: {
        width: "",
      },
      label: {
        width: "",
      },
    },
  },
  colors: {
    brand: "",
    tableBorder: "",
    backgroundSecondary: "",
    background: "",
    text: "",
    inputBorder: "",
    inputBackground: "",
    success: "",
    error: "",
    button: "",
    buttonActive: "",
    buttonHover: "",
  },
  spacings: {
    s: "",
    m: "",
    l: "",
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
  animation: {
    duration: {
      m: "",
    },
    timingFunction: {
      replace: "",
    },
  },
});
