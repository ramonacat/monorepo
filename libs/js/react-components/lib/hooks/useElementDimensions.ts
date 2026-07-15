import { useLayoutEffect, useState, type RefObject } from "react";
import { Vector2 } from "../math";

export function useElementDimensions<T extends HTMLElement>(
  element: RefObject<T | null>,
): Vector2 {
  const [dimensions, setDimensions] = useState(Vector2.zero());

  useLayoutEffect(() => {
    if (element.current === null) {
      return;
    }

    const elementValue = element.current;

    const resizeObserver = new ResizeObserver((entries) => {
      const [{ blockSize, inlineSize }] = entries[0].contentBoxSize;

      setDimensions(new Vector2(inlineSize, blockSize));
    });

    resizeObserver.observe(elementValue);

    return () => {
      resizeObserver.unobserve(elementValue);
    };
  }, [element]);

  return dimensions;
}
