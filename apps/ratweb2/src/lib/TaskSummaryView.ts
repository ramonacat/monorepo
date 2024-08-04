import { DateTime } from 'luxon';

export interface TaskSummaryView {
	name: string;
	deadline?: DateTime<boolean>;
	pastDeadline: boolean;
}
