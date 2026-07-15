import type { IconType } from "react-icons";
import { InterpolatedValue } from "../../math/InterpolatedValue";
import { clamp, lerp, Vector2 } from "../../math";

export type VertexStyle = {
  color: string;
  icon?: { icon: IconType; color: string };
  label?: { textColor: string; backgroundColor: string; font: string };
};

export type EdgeStyle = {
  color: string;
  livenessIndicatorColor: string;
  livenessIndicatorIcon: { icon: IconType; color: string };
};

export type Vertex = {
  id: string;
  name: string;

  radius: InterpolatedValue;
  style: VertexStyle;
};

export type Edge = {
  start: string;
  end: string;

  width: InterpolatedValue;
  livenessAnimationProgress: InterpolatedValue;
  style: EdgeStyle;
};

export class InterpolatedPosition {
  constructor(
    private x: InterpolatedValue,
    private y: InterpolatedValue,
  ) {}

  valueAt(now: DOMHighResTimeStamp) {
    return new Vector2(this.x.valueAt(now), this.y.valueAt(now));
  }

  setEndValue(value: Vector2) {
    this.x.setEndValue(value.x);
    this.y.setEndValue(value.y);
  }
}

export class GraphData {
  private vertices: Record<string, Vertex> = {};
  private positions: Record<string, Vector2> = {};
  private mappedPositions: Record<string, InterpolatedPosition> = {};
  private edges: Edge[] = [];
  private width: number;
  private height: number;
  private temperature: number;

  constructor(width: number, height: number) {
    this.temperature = width / 30;

    this.width = width;
    this.height = height;
  }

  private recalculatePositions() {
    this.temperature = this.width / 30;

    for (let i = 0; i < 100; i++) {
      this.positioningTick();
    }
  }

  upsertVertex({
    id,
    radius,
    name,
    style,
  }: {
    id: string;
    radius: number;
    name: string;
    style: VertexStyle;
  }) {
    if (id in this.vertices) {
      this.vertices[id].name = name;
      this.vertices[id].radius.setEndValue(radius);
    } else {
      const position = new Vector2(
        Math.random() * this.width,
        Math.random() * this.height,
      );
      this.vertices[id] = {
        id,
        name,
        radius: new InterpolatedValue(radius, radius, 5000),
        style,
      };
      this.positions[id] = position;
      this.mappedPositions[id] = new InterpolatedPosition(
        new InterpolatedValue(position.x, position.x, 500),
        new InterpolatedValue(position.y, position.y, 500),
      );
    }
  }

  removeVertex(id: string) {
    if (!(id in this.vertices)) {
      return;
    }
    delete this.vertices[id];
    delete this.positions[id];
    delete this.mappedPositions[id];
    this.edges = [...this.edges.filter((x) => x.start !== id && x.end !== id)];

    this.recalculatePositions();
  }

  upsertEdge(edge: {
    start: string;
    end: string;
    width: number;
    liveness: number;
    style: EdgeStyle;
  }) {
    const currentIndex = this.edges.findIndex(
      (x) => x.start === edge.start && x.end === edge.end,
    );

    const animationDuration = lerp(10000, 3000, clamp(edge.liveness, 0, 1));

    if (currentIndex === -1) {
      this.edges.push({
        start: edge.start,
        end: edge.end,
        width: new InterpolatedValue(0, edge.width, 500),
        livenessAnimationProgress: new InterpolatedValue(
          0,
          1,
          animationDuration,
          true,
        ),
        style: edge.style,
      });
      this.recalculatePositions();
    } else {
      this.edges[currentIndex].width.setEndValue(edge.width);
      this.edges[currentIndex].livenessAnimationProgress.setDuration(
        animationDuration,
      );

      if (edge.liveness === 0) {
        this.edges[currentIndex].livenessAnimationProgress.holdAt(0);
      } else {
        this.edges[currentIndex].livenessAnimationProgress.resume();
      }
    }
  }

  positioningTick() {
    if (this.temperature < 0.01) {
      return;
    }

    const vertexEntries = Object.entries(this.vertices);
    const k = Math.sqrt((this.width * this.height) / vertexEntries.length);

    const forces: Record<string, Vector2> = Object.fromEntries(
      vertexEntries.map(([_, vertex]) => [vertex.id, Vector2.zero()]),
    );

    for (let i = 0; i < vertexEntries.length; i++) {
      const [, vertexI] = vertexEntries[i];

      for (let j = i + 1; j < vertexEntries.length; j++) {
        const [, vertexJ] = vertexEntries[j];

        const iPosition = this.positions[vertexI.id];
        const jPosition = this.positions[vertexJ.id];

        const delta = jPosition.subtract(iPosition);
        const distance = Math.max(10, delta.magnitude());
        const force = (Math.pow(k, 2) / distance) * 4;
        const forceVector = delta.divideScalar(distance).multiplyScalar(force);

        forces[vertexI.id] = forces[vertexI.id].subtract(forceVector);
        forces[vertexJ.id] = forces[vertexJ.id].add(forceVector);
      }
    }

    for (const [, vertex] of vertexEntries) {
      const center = new Vector2(this.width / 2, this.height / 2);
      const delta = center.subtract(this.positions[vertex.id]);
      const distance = Math.max(25, delta.magnitude());
      const force = (Math.pow(distance, 2) / k) * -0.15;
      const forceVector = delta.divideScalar(distance).multiplyScalar(force);

      forces[vertex.id] = forces[vertex.id].subtract(forceVector);
    }

    for (const edge of this.edges) {
      const delta = this.positions[edge.start].subtract(
        this.positions[edge.end],
      );
      const distance = Math.max(50, delta.magnitude());
      const force = (Math.pow(distance, 2) / k) * 0.3;
      const forceVector = delta.divideScalar(distance).multiplyScalar(force);

      forces[edge.end] = forces[edge.end].add(forceVector);
      forces[edge.start] = forces[edge.start].subtract(forceVector);
    }

    for (const id of Object.keys(this.vertices)) {
      const magnitude = forces[id].magnitude();
      const displacement =
        magnitude >= 1e-10
          ? Math.min(magnitude, this.temperature) / magnitude
          : 0;

      this.positions[id] = this.positions[id].add(
        forces[id].multiplyScalar(displacement),
      );
    }

    this.temperature *= 0.95;

    let minCoords = new Vector2(Number.MAX_VALUE, Number.MAX_VALUE);
    let maxCoords = Vector2.zero();

    for (const id of Object.keys(this.vertices)) {
      const position = this.positions[id];

      minCoords = new Vector2(
        Math.min(minCoords.x, position.x),
        Math.min(minCoords.y, position.y),
      );
      maxCoords = new Vector2(
        Math.max(maxCoords.x, position.x),
        Math.max(maxCoords.y, position.y),
      );
    }

    const margin = new Vector2(300, 300);

    minCoords = minCoords.subtract(margin);
    maxCoords = maxCoords.add(margin);

    const coordsRange = maxCoords.subtract(minCoords);

    const scale = new Vector2(
      this.width / coordsRange.x,
      this.height / coordsRange.y,
    );

    for (const id of Object.keys(this.positions)) {
      const position = this.positions[id];
      const mapped = position.subtract(minCoords).multiplyElementwise(scale);

      this.mappedPositions[id].setEndValue(mapped);
    }
  }

  get() {
    return {
      vertices: this.vertices,
      edges: this.edges,
      mappedPositions: this.mappedPositions,
    };
  }

  setDimensions(width: number, height: number) {
    this.width = width;
    this.height = height;
  }

  clear() {
    this.vertices = {};
    this.edges = [];
  }
}
