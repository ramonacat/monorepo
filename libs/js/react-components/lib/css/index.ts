import { themePrivate } from "./theme-private.css";
import "./global.css.ts";
import { vars } from "../theme-contract.css.ts";

document.documentElement.classList.add(themePrivate);

// yes, this is a bit hacky, but it's useful to use theme colors on <canvas /> without hardcoding them
function extractVariableName(value: string) {
  const variableName = value.match(/^var\((?<variableName>.*)\)$/)?.groups
    ?.variableName;

  if (!variableName) {
    throw new Error("failed to parse theme variable");
  }

  return variableName;
}

export function readThemeColor(name: keyof typeof vars.colors) {
  const variableName = extractVariableName(vars.colors[name]);

  return getComputedStyle(document.body).getPropertyValue(variableName);
}

export function readThemeFont(name: keyof typeof vars.fonts.families) {
  const variableName = extractVariableName(vars.fonts.families[name]);

  return getComputedStyle(document.body).getPropertyValue(variableName);
}
