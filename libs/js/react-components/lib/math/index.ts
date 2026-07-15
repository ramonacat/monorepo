export function lerp(start: number, end: number, t: number) {
  return start + (end - start) * t;
}

export function clamp(value: number, min: number, max: number) {
  if (value < min) {
    return min;
  }

  if (value > max) {
    return max;
  }

  return value;
}

export class Vector2 {
  static zero() {
    return new Vector2(0, 0);
  }

  constructor(
    public readonly x: number,
    public readonly y: number,
  ) {}

  add(other: Vector2) {
    return new Vector2(this.x + other.x, this.y + other.y);
  }

  subtract(other: Vector2) {
    return new Vector2(this.x - other.x, this.y - other.y);
  }

  divideScalar(value: number) {
    return new Vector2(this.x / value, this.y / value);
  }

  multiplyScalar(value: number) {
    return new Vector2(this.x * value, this.y * value);
  }

  multiplyElementwise(other: Vector2) {
    return new Vector2(this.x * other.x, this.y * other.y);
  }

  magnitude(): number {
    return Math.sqrt(Math.pow(this.x, 2) + Math.pow(this.y, 2));
  }

  rotate(radians: number) {
    return new Vector2(
      Math.cos(radians) * this.x - Math.sin(radians) * this.y,
      Math.sin(radians) * this.x + Math.cos(radians) * this.y,
    );
  }

  dot(other: Vector2) {
    return this.x * other.x + this.y * other.y;
  }

  cross(other: Vector2) {
    return this.x * other.y - this.y * other.x;
  }

  // this is correct because I stole the formula, QED: https://github.com/servo/euclid/blob/main/src/vector.rs#L570
  angleTo(other: Vector2) {
    return Math.atan2(this.cross(other), this.dot(other));
  }

  normalize() {
    return new Vector2(this.x / this.magnitude(), this.y / this.magnitude());
  }

  lerp(other: Vector2, t: number) {
    return new Vector2(lerp(this.x, other.x, t), lerp(this.y, other.y, t));
  }
}

export class Circle {
  constructor(
    public readonly position: Vector2,
    public readonly radius: number,
  ) {}

  contains(point: Vector2) {
    return this.position.subtract(point).magnitude() < this.radius;
  }
}
