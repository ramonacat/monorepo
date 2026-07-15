import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";
import react from "eslint-plugin-react";
import { defineConfig, globalIgnores } from "eslint/config";
import vanillaExtract from "@antebudimir/eslint-plugin-vanilla-extract";

export default defineConfig([
  {
    files: ["**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],
    plugins: { js, react },
    extends: ["js/recommended"],
    languageOptions: { globals: globals.browser },
  },
  globalIgnores(["dist/**"]),
  tseslint.configs.recommended,
  (vanillaExtract.configs as { recommended: object }).recommended,
  {
    rules: {
      "vanilla-extract/no-px-unit": "error",
      "vanilla-extract/no-unitless-values": "error",
      "vanilla-extract/prefer-theme-tokens": "error",
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_" },
      ],
      camelcase: "error",
      eqeqeq: "error",
      "object-shorthand": "error",
      "no-prototype-builtins": "error",
      "prefer-destructuring": "error",
      "prefer-template": "error",
      "template-curly-spacing": "error",
      "no-param-reassign": [
        "error",
        { props: true, ignorePropertyModificationsFor: ["state"] },
      ],
      "prefer-arrow-callback": "error",
      "dot-notation": "error",
      // prettier deals with quotes
      quotes: "off",
    },
  },
]);
