import type { IconType } from "react-icons";
import { Vector2 } from "../../math";
import type { Edge, InterpolatedPosition, Vertex } from "./GraphData";
import { IconCache } from "./IconCache";

export class Renderer {
  private iconCache: IconCache;
  private context: CanvasRenderingContext2D;

  constructor(context: CanvasRenderingContext2D) {
    this.iconCache = new IconCache();
    this.context = context;
  }

  draw({
    edges,
    height,
    mappedPositions,
    now,
    vertices,
    width,
  }: {
    now: DOMHighResTimeStamp;
    width: number;
    height: number;
    vertices: Record<string, Vertex>;
    edges: Edge[];
    mappedPositions: Record<string, InterpolatedPosition>;
  }) {
    this.context.clearRect(0, 0, width, height);
    this.context.lineWidth = 2;

    this.context.save();
    this.drawEdges(edges, mappedPositions, now);
    this.context.restore();

    this.context.save();
    this.drawVertices(vertices, mappedPositions, width, height, now);
    this.context.restore();
  }

  drawEdges(
    edges: Edge[],
    mappedPositions: Record<string, InterpolatedPosition>,
    now: DOMHighResTimeStamp,
  ) {
    const renderedEdges: Record<string, boolean> = {};

    for (const edge of edges) {
      const hasOpposingEdge =
        edges.find((x) => x.start === edge.end && x.end === edge.start) !==
        undefined;
      const opposingEdgeWasRendered =
        renderedEdges[`${edge.end} ${edge.start}`] !== undefined;
      const edgeEndOffset = hasOpposingEdge
        ? opposingEdgeWasRendered
          ? 15
          : -15
        : 0;
      renderedEdges[`${edge.start} ${edge.end}`] = true;

      const start = mappedPositions[edge.start]!.valueAt(now);
      const end = mappedPositions[edge.end]!.valueAt(now);
      const width = edge.width.valueAt(now);

      const startOffset = start
        .rotate(-Math.PI / 2)
        .normalize()
        .multiplyScalar(edgeEndOffset);
      const finalStart = start.add(startOffset);

      const endOffset = end
        .rotate(-Math.PI / 2)
        .normalize()
        .multiplyScalar(edgeEndOffset);
      const finalEnd = end.add(endOffset);

      this.context.save();
      this.context.strokeStyle = edge.style.color;
      this.context.lineWidth = width;
      this.context.beginPath();
      this.context.moveTo(finalStart.x, finalStart.y);
      this.context.lineTo(finalEnd.x, finalEnd.y);
      this.context.stroke();
      this.context.restore();

      this.drawLivenessAnimation(finalStart, finalEnd, edge, width + 7, now);
    }
  }

  drawLivenessAnimation(
    start: Vector2,
    end: Vector2,
    edge: Edge,
    radius: number,
    now: DOMHighResTimeStamp,
  ) {
    const animationProgress = edge.livenessAnimationProgress.valueAt(now);

    this.context.save();
    this.context.fillStyle = edge.style.livenessIndicatorColor;
    this.context.beginPath();
    const indicatorPosition = start.lerp(end, animationProgress);
    this.context.arc(
      indicatorPosition.x,
      indicatorPosition.y,
      radius,
      0,
      Math.PI * 2,
    );
    this.context.fill();

    const { icon, color } = edge.style.livenessIndicatorIcon;

    const iconRotation = new Vector2(0, 1).angleTo(start.subtract(end));

    this.drawIcon(icon, color, indicatorPosition, radius * 1.5, iconRotation);
  }

  drawVertices(
    vertices: Record<string, Vertex>,
    mappedPositions: Record<string, InterpolatedPosition>,
    width: number,
    height: number,
    now: DOMHighResTimeStamp,
  ) {
    for (const id in vertices) {
      const vertex = vertices[id];
      const radius = vertex.radius.valueAt(now);
      const position = mappedPositions[vertex.id].valueAt(now);

      this.context.save();
      this.context.fillStyle = vertex.style.color;
      this.context.beginPath();
      this.context.arc(position.x, position.y, radius, 0, 2 * Math.PI);
      this.context.fill();
      this.context.restore();

      if (vertex.style.icon !== undefined) {
        const { icon, color } = vertex.style.icon;
        const iconWidth = radius * 1.2;

        this.drawIcon(icon, color, position, iconWidth);
      }

      if (vertex.style.label) {
        const { backgroundColor, textColor, font } = vertex.style.label;
        this.context.restore();
        this.context.save();
        this.context.font = font;

        const textOffset = radius + 4;
        const textMetrics = this.context.measureText(vertex.name);

        const textHeight =
          textMetrics.actualBoundingBoxAscent +
          textMetrics.actualBoundingBoxDescent;
        const textWidth =
          textMetrics.actualBoundingBoxRight -
          textMetrics.actualBoundingBoxLeft;

        const textPosition = position.add(
          new Vector2(
            position.x < width / 2 ? textOffset : -(textOffset + textWidth),
            position.y < height / 2 ? textOffset : -textOffset,
          ),
        );
        const padding = 5;
        this.context.fillStyle = backgroundColor;
        this.context.fillRect(
          textPosition.x - padding,
          textPosition.y - textHeight - padding,
          textWidth + 2 * padding,
          textHeight + 2 * padding,
        );

        this.context.fillStyle = textColor;

        this.context.fillText(vertex.name, textPosition.x, textPosition.y);

        this.context.restore();
      }
    }
  }

  drawIcon(
    icon: IconType,
    color: string,
    position: Vector2,
    size: number,
    rotation: number = 0,
  ) {
    this.context.save();
    this.context.transform(1, 0, 0, 1, position.x, position.y);
    this.context.rotate(rotation);
    this.context.drawImage(
      this.iconCache.renderIcon(icon, color),
      -(size / 2),
      -(size / 2),
      size,
      size,
    );
    this.context.restore();
  }
}
