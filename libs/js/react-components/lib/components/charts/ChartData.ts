import { DataWindow } from "../../math/DataWindow";

export type Value =
  | { kind: "Number"; value: number }
  | { kind: "None" }
  | { kind: "Label"; value: string };
export type Entry = { when: number; value: Value };

export type InternalEntry = Entry & { id: number };

export class ChartData {
  private entries: DataWindow<InternalEntry>;
  private counter: number = 0;

  constructor(windowSize: number) {
    this.entries = new DataWindow(windowSize, (x) => x.when);
  }

  add(entry: Entry) {
    this.entries.addValue({ ...entry, id: this.counter });
    this.counter++;
  }

  replaceAll(entries: Entry[]) {
    this.clear();

    for (const entry of entries) {
      this.add(entry);
    }
  }

  clear() {
    this.counter = 0;
    this.entries.clear();
  }

  items(): readonly InternalEntry[] {
    return this.entries.currentValues();
  }
}
