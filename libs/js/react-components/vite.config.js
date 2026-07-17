import { resolve } from "node:path";
import { defineConfig } from "vite";
import dts from "unplugin-dts/vite";
import { vanillaExtractPlugin } from "@vanilla-extract/vite-plugin";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [dts(), react(), vanillaExtractPlugin()],
  build: {
    lib: {
      name: "react-components",
      entry: {
        icons: resolve(import.meta.dirname, "./lib/icons.ts"),
        "components/button/index": resolve(
          import.meta.dirname,
          "./lib/components/button/index.tsx",
        ),
        "components/charts/index": resolve(
          import.meta.dirname,
          "./lib/components/charts/index.tsx",
        ),
        "components/code-editor/index": resolve(
          import.meta.dirname,
          "./lib/components/code-editor/index.tsx",
        ),
        "components/form/index": resolve(
          import.meta.dirname,
          "./lib/components/form/index.tsx",
        ),
        "components/graph/index": resolve(
          import.meta.dirname,
          "./lib/components/graph/index.tsx",
        ),
        "components/modal/index": resolve(
          import.meta.dirname,
          "./lib/components/modal/index.tsx",
        ),
        "components/section/index": resolve(
          import.meta.dirname,
          "./lib/components/section/index.tsx",
        ),
        "components/table/index": resolve(
          import.meta.dirname,
          "./lib/components/table/index.tsx",
        ),
        css: resolve(import.meta.dirname, "./lib/css/index.ts"),
        "css/theme-contract.css": resolve(
          import.meta.dirname,
          "./lib/css/theme-contract.css.ts",
        ),
        "math/index": resolve(import.meta.dirname, "./lib/math/index.ts"),
        "hooks/index": resolve(import.meta.dirname, "./lib/hooks/index.ts"),
      },
      formats: ["es"],
    },
    rolldownOptions: {
      // this is the recommended way to make everything external: https://rolldown.rs/reference/InputOptions.external#avoid-node-modules-for-npm-packages
      external: /^[^./](?!:[/\\])/,
    },
  },
});
