import { DateTime } from 'luxon';

export interface CurrentTaskView {
	id: string;
	title: string;
	startTime: DateTime;
	isPaused: boolean;
}
