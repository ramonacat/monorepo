import { lerp } from ".";

export class InterpolatedValue {
  private readonly autoRepeat: boolean;

  private startValue: number;
  private endValue: number;
  private duration: number;
  private latestTime: number | null = null;
  private start: number | null = null;
  private hold: number | null = null;

  constructor(
    startValue: number,
    endValue: number,
    interpolationTime: number,
    autoRepeat: boolean = false,
  ) {
    this.startValue = startValue;
    this.endValue = endValue;
    this.duration = interpolationTime;
    this.autoRepeat = autoRepeat;
  }

  valueAt(time: number): number {
    this.latestTime = time;

    if (this.hold !== null) {
      return this.hold;
    }

    if (this.start === null) {
      this.start = time;
    }

    const timeSinceStart = time - this.start;
    if (timeSinceStart >= this.duration) {
      if (this.autoRepeat) {
        this.start = null;
        return this.valueAt(time);
      }
      return this.endValue;
    }

    return lerp(this.startValue, this.endValue, timeSinceStart / this.duration);
  }

  getEndValue() {
    return this.endValue;
  }

  setEndValue(value: number) {
    if (this.start === null || this.latestTime === null) {
      // the animation hasn't started, there's nothing to adjust
      this.endValue = value;
      return;
    }
    const currentValue = this.valueAt(this.latestTime);

    if (!this.autoRepeat) {
      this.startValue = currentValue;
      this.start = this.latestTime;
    }

    this.endValue = value;
  }

  setDuration(duration: number) {
    if (duration === this.duration) {
      return;
    }

    if (this.start !== null && this.latestTime !== null) {
      this.start =
        this.latestTime -
        (this.latestTime - this.start) * (duration / this.duration);
    }

    this.duration = duration;
  }

  holdAt(value: number) {
    this.hold = value;
  }

  resume() {
    this.hold = null;
  }
}
