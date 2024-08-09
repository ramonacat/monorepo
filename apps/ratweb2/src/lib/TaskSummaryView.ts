import { DateTime } from 'luxon';

export interface TaskSummaryView {
	title: string;
	deadline?: DateTime<boolean>;
	pastDeadline: boolean;
	tags: string[];
}
