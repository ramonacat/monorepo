import { DateTime } from 'luxon';
import type { ServerDateTime } from '$lib/ServerDateTime';

export interface TaskSummaryView {
	id: string;
	title: string;
	deadline?: DateTime<boolean> | null;
	pastDeadline: boolean;
	tags: string[];
	timeRecords: { started: ServerDateTime; ended: ServerDateTime | undefined }[];
}
