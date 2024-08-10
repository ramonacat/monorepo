import { DateTime } from 'luxon';

export interface TaskSummaryView {
	id: string;
	title: string;
	deadline?: DateTime<boolean> | null;
	pastDeadline: boolean;
	tags: string[];
}
