import type { DateTime, Duration } from 'luxon';

export interface ActiveTaskView {
	name: string;
	workStartedAt: DateTime;
}
