import { resolve } from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    lib: {
      name: "react-components",
      entry: {
        icons: resolve(import.meta.dirname, "./lib/icons.ts"),
        "components/Button": resolve(
          import.meta.dirname,
          "./lib/components/button/Button.tsx",
        ),
        "components/charts/LiveLineChart": resolve(
          import.meta.dirname,
          "./lib/components/charts/LiveLineChart.tsx",
        ),
        "components/CodeEditor": resolve(
          import.meta.dirname,
          "./lib/components/code-editor/CodeEditor.tsx",
        ),
        "components/Form": resolve(
          import.meta.dirname,
          "./lib/components/form/Form.tsx",
        ),
        "components/graph/Graph": resolve(
          import.meta.dirname,
          "./lib/components/graph/Graph.tsx",
        ),
        "components/graph/graph-data": resolve(
          import.meta.dirname,
          "./lib/components/graph/GraphData.ts",
        ),
        "components/Modal": resolve(
          import.meta.dirname,
          "./lib/components/modal/Modal.tsx",
        ),
        "components/Section": resolve(
          import.meta.dirname,
          "./lib/components/section/Section.tsx",
        ),
        "components/Table": resolve(
          import.meta.dirname,
          "./lib/components/table/Table.tsx",
        ),
        css: resolve(import.meta.dirname, "./lib/css/index.ts"),
        "css/theme-contract.css": resolve(
          import.meta.dirname,
          "./lib/css/theme-contract.css.ts",
        ),
        math: resolve(import.meta.dirname, "./lib/math/index.ts"),
      },
      formats: ["es"],
    },
    rolldownOptions: {
      // this is the recommended way to make everything external: https://rolldown.rs/reference/InputOptions.external#avoid-node-modules-for-npm-packages
      external: /^[^./](?!:[/\\])/,
    },
  },
});
