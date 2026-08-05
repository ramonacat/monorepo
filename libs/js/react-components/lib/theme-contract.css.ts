import { createThemeContract } from "@vanilla-extract/css";

// TODO this needs more thorough cleanup
export const vars = createThemeContract({
  defaults: {
    colors: {
      background: "",
      backgroundSecondary: "",
      brand: "",

      error: "",
      success: "",
    },
    shadows: {
      highlight: "",
    },
    sizes: {
      border: {
        xs: "",
        s: "",
      },
    },
    spacings: {
      s: "",
      m: "",
      l: "",
    },
    animation: {
      duration: {
        m: "",
      },
      timingFunction: {
        replace: "",
      },
    },
  },
  icon: {
    sizes: {
      xxl: "",
    },
  },
  button: {
    colors: {
      normal: "",
      active: "",
      hover: "",
    },
  },
  input: {
    colors: {
      background: "",
      border: "",
    },
    sizes: {
      width: "",
      border: "",
    },
  },
  label: {
    sizes: { width: "" },
  },
  text: {
    colors: {
      normal: "",
      header: "",
    },
    sizes: {
      root: "",
      primary: "",
      h1: "",
      h2: "",
      h3: "",
      h4: "",
      h5: "",
      h6: "",
      attention: "",
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
  },
  link: {
    colors: {
      normal: "",
      hover: "",
    },
  },
  table: {
    colors: {
      border: "",
    },
  },
  modal: {
    backdrop: {
      color: "",
      filter: "",
    },
  },
});
