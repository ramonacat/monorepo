export class DataWindow<Value> {
  private windowSeconds: number;
  private values: Value[];
  private getTime: (value: Value) => number;

  constructor(windowSeconds: number, getTime: (value: Value) => number) {
    this.windowSeconds = windowSeconds;
    this.getTime = getTime;
    this.values = [];
  }

  addValue(value: Value) {
    this.values.push(value);
  }

  clear() {
    this.values = [];
  }

  currentValues() {
    if (this.values.length > 0) {
      const last = this.values[this.values.length - 1];
      this.values = [
        ...this.values.filter(
          (x) => this.getTime(last) - this.getTime(x) <= this.windowSeconds,
        ),
      ];
    }
    return Object.freeze([...this.values]);
  }
}
