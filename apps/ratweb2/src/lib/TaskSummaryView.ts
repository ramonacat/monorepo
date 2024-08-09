import { DateTime } from 'luxon';

export interface TaskSummaryView {
	title: string;
	deadline?: DateTime<boolean> | null;
	pastDeadline: boolean;
	tags: string[];
}
