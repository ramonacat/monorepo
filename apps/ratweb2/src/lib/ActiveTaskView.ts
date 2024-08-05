import type { Duration } from 'luxon';

export interface ActiveTaskView {
	name: string;
	timeSpent: Duration;
}
