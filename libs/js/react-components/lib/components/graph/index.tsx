import {
  useEffect,
  useRef,
  type CanvasHTMLAttributes,
  type RefObject,
} from "react";
import { GraphData } from "./GraphData";
import { Circle, Vector2 } from "../../math";
import { Renderer } from "./Renderer";
import { useDpi } from "../../hooks/useDpi";
import { useElementDimensions } from "../../hooks/useElementDimensions";

export { GraphData };

export function Graph({
  data,
  onMouseEnter,
  onMouseExit,
  ref: propsRef,
  ...props
}: {
  data: RefObject<GraphData>;
  ref?: RefObject<HTMLCanvasElement | null>;
  onMouseEnter?: (vertexId: string, coordinates: Vector2) => void;
  onMouseExit?: (vertexId: string) => void;
} & CanvasHTMLAttributes<HTMLCanvasElement>) {
  const ref = useRef<HTMLCanvasElement | null>(null);
  const dpi = useDpi();
  const dimensions = useElementDimensions<HTMLCanvasElement>(ref);

  useEffect(() => {
    if (propsRef !== undefined) {
      // eslint-disable-next-line no-param-reassign
      propsRef.current = ref.current;
    }
  }, [ref]);

  useEffect(() => {
    if (ref.current === null) {
      return;
    }

    const canvas = ref.current;
    const context = canvas.getContext("2d")!;
    context.scale(dpi, dpi);

    const renderer = new Renderer(context);

    let stopRendering = false;
    const requestAnimationFrameCallback = (now: DOMHighResTimeStamp) => {
      if (stopRendering) {
        return;
      }

      const { vertices, edges, mappedPositions } = data.current.get();
      renderer.draw({
        now,
        vertices,
        edges,
        mappedPositions,
        height: dimensions.y,
        width: dimensions.x,
      });

      requestAnimationFrame(requestAnimationFrameCallback);
    };

    requestAnimationFrame(requestAnimationFrameCallback);

    const positioningTimerId = setInterval(
      () => data.current.positioningTick(),
      200,
    );
    data.current.positioningTick();

    return () => {
      stopRendering = true;
      clearInterval(positioningTimerId);
    };
  }, [data, dimensions, ref, dpi]);

  useEffect(() => {
    if (ref.current === null) {
      return;
    }

    if (onMouseEnter === undefined && onMouseExit === undefined) {
      return;
    }

    let currentlyHovered: string | null = null;

    const mousemoveHandler = (move: MouseEvent) => {
      const now = performance.now();
      const { vertices, mappedPositions } = data.current.get();

      let anyHasHover = false;
      for (const id in vertices) {
        const vertex = vertices[id];

        const radius = vertex.radius.valueAt(now);
        const position = mappedPositions[id].valueAt(now);

        const vertexCircle = new Circle(position, radius);

        const mousePosition = new Vector2(move.offsetX, move.offsetY);

        if (vertexCircle.contains(mousePosition)) {
          anyHasHover = true;

          if (currentlyHovered !== id) {
            if (currentlyHovered !== null) {
              onMouseExit?.(currentlyHovered);
            }

            onMouseEnter?.(id, mousePosition);
            currentlyHovered = id;
          }
          break;
        }
      }

      if (currentlyHovered !== null && !anyHasHover) {
        onMouseExit?.(currentlyHovered);
        currentlyHovered = null;
      }
    };

    const canvas = ref.current;
    canvas.addEventListener("mousemove", mousemoveHandler);

    return () => canvas.removeEventListener("mousemove", mousemoveHandler);
  }, [onMouseEnter, onMouseExit, ref, data]);

  useEffect(() => {
    if (data.current === null) {
      return;
    }

    data.current.setDimensions(dimensions.x, dimensions.y);
  }, [data, dimensions]);

  return (
    <canvas
      ref={ref}
      width={dimensions.x * dpi}
      height={dimensions.y * dpi}
      {...props}
    ></canvas>
  );
}
