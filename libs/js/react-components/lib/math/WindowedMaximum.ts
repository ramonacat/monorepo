type Entry = { when: number; value: number };
export class WindowedMaximum {
  private previousMaximums: Entry[] = [];
  private values: Entry[] = [];
  private windowSize: number;
  private longWindowSize: number;

  constructor(
    now: DOMHighResTimeStamp,
    windowSize: number,
    longWindowSize: number,
    initialValue?: number,
  ) {
    this.windowSize = windowSize * 1000;
    this.longWindowSize = longWindowSize * 1000;

    if (initialValue !== undefined) {
      this.values.push({ when: now, value: initialValue });
    }
  }

  addValue(value: number, now: DOMHighResTimeStamp) {
    const entry = { when: now, value };

    if (this.values.length === 0) {
      this.values.push(entry);

      return;
    }

    const maximum = this.values.reduce(
      (prev, cur) => (prev.value > cur.value ? prev : cur),
      this.values[0],
    );
    this.values = [
      ...this.values.filter((x) => now - x.when <= this.windowSize),
      entry,
    ];
    const maximumAfter = this.values.reduce(
      (prev, cur) => (prev.value > cur.value ? prev : cur),
      this.values[0],
    );

    if (maximumAfter.value < maximum.value) {
      this.previousMaximums.push(maximum);
    }
  }

  averageMaximum(now: DOMHighResTimeStamp) {
    if (this.values.length === 0) {
      return 0;
    }

    if (this.previousMaximums.length === 0) {
      return Math.max(...this.values.map((x) => x.value));
    }

    this.previousMaximums = [
      ...this.previousMaximums.filter(
        (x) => now - x.when <= this.longWindowSize,
      ),
    ];

    return (
      this.previousMaximums
        .map((x) => ({
          weight: Math.sqrt((now - x.when) / this.longWindowSize),
          value: x.value,
        }))
        .reduce((prev, cur) => prev + cur.weight * cur.value, 0) /
      this.previousMaximums.length
    );
  }
}
