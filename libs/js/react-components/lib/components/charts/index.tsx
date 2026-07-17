import {
  useEffect,
  useRef,
  type CanvasHTMLAttributes,
  type ReactNode,
  type RefObject,
} from "react";
import { ChartData, type InternalEntry } from "./chart-data";
import { useElementDimensions } from "../../hooks/useElementDimensions";
import { readThemeFont } from "../../css";
import { useDpi } from "../../hooks/useDpi";

export { ChartData };

export function LiveLineChart(
  allProps: {
    windowSize: number;
    data: RefObject<ChartData>;
    lineColor: string;
    textColor: string;
    disconnectThreshold?: number;
    markerRadius?: number;
  } & Omit<CanvasHTMLAttributes<HTMLCanvasElement>, "height" | "width">,
): ReactNode {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const dimensions = useElementDimensions<HTMLCanvasElement>(canvasRef);
  const {
    windowSize,
    data,
    lineColor,
    textColor,
    disconnectThreshold = 1,
    className,
    markerRadius = 10,
    ...props
  } = allProps;
  const width = dimensions.x;
  const height = dimensions.y;
  const dpi = useDpi();

  useEffect(() => {
    if (canvasRef.current === null) {
      return;
    }

    const context = canvasRef.current.getContext("2d")!;
    context.scale(dpi, dpi);
    context.lineWidth = 2;
    context.strokeStyle = lineColor;
    context.fillStyle = textColor;
    context.font = `16px ${readThemeFont("default")}`;
    const redrawCanvas = (items: readonly InternalEntry[]) => {
      const now = Date.now() / 1000;
      const start = now - windowSize;

      let lastTime = 0;

      context.clearRect(0, 0, width, height);

      context.beginPath();
      for (const item of items) {
        const x = ((item.when - start) / windowSize) * width;
        const timeSinceLast = item.when - lastTime;

        if (item.value.kind === "Number") {
          // invert y, as canvas coordinates start at top-left, therefore item.value*height would put highest values on the bottom
          const y = (1 - item.value.value) * height;

          if (timeSinceLast > disconnectThreshold) {
            context.moveTo(x, y);
          } else {
            context.lineTo(x, y);
          }
        } else if (item.value.kind === "None" || item.value.kind === "Label") {
          const y = 0.5 * height;

          context.stroke();
          context.beginPath();
          context.arc(x, y, markerRadius, 0, 2 * Math.PI);
          context.stroke();

          if (item.value.kind === "Label") {
            const textSize = context.measureText(item.value.value);
            const labelY =
              y +
              markerRadius * 2.5 +
              (item.id % 2 === 0
                ? (textSize.actualBoundingBoxAscent +
                    textSize.actualBoundingBoxDescent) *
                  1.5
                : 0);
            const labelX = x - textSize.width / 2;

            context.fillText(item.value.value, labelX, labelY);
          }
        }

        lastTime = item.when;
      }
      context.stroke();
    };

    let stopRendering = false;

    const requestAnimationFrameCallback = () => {
      if (stopRendering) {
        return;
      }

      redrawCanvas(data.current.items());
      requestAnimationFrame(requestAnimationFrameCallback);
    };

    requestAnimationFrame(requestAnimationFrameCallback);

    return () => {
      stopRendering = true;
    };
  }, [data, canvasRef, width, height]);

  return (
    <>
      <canvas
        className={className}
        ref={canvasRef}
        width={width * dpi}
        height={height * dpi}
        {...props}
      />
    </>
  );
}
