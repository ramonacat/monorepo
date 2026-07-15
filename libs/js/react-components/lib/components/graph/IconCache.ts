import { createElement } from "react";
import { flushSync } from "react-dom";
import { createRoot } from "react-dom/client";
import type { IconType } from "react-icons";

// yes, it's unholy, but it works
export class IconCache {
  private cache: Map<IconType, Record<string, string>> = new Map();

  renderIcon(icon: IconType, color: string) {
    if (!this.cache.has(icon)) {
      this.cache.set(icon, {});
    }

    const iconEntries = this.cache.get(icon)!;
    if (!(color in iconEntries)) {
      const virtualRoot = document.createElement("div");

      flushSync(() => {
        const reactRoot = createRoot(virtualRoot);
        reactRoot.render(createElement(icon, { color }));
      });

      const svgElement = virtualRoot.querySelector("svg")!;
      const svgText = svgElement.outerHTML;
      const base64 = btoa(svgText ?? "");

      iconEntries[color] = base64;
    }
    const base64 = iconEntries[color];
    const imgElement = document.createElement("img");
    const src = `data:image/svg+xml;base64,${base64}`;
    imgElement.setAttribute("src", src);

    return imgElement;
  }
}
