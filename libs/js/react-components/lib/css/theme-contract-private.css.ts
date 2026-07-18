import { createThemeContract } from "@vanilla-extract/css";

export const privateVars = createThemeContract({
  sizes: {
    border: {
      xs: "",
      s: "",
    },
    font: {
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
});
