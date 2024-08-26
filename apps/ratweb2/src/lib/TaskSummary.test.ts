import { expect, test } from 'vitest';
import { TaskSummary } from '$lib/TaskSummary';
import { ServerDateTime } from '$lib/Api';

test('can create summary from pojo', function () {
	const deadline = {
		timestamp: '2024-01-01 00:00:00',
		timezone: 'Europe/Berlin'
	};
	const summary = TaskSummary.fromPojo({
		id: 'test',
		assigneeId: 'test-a',
		tags: ['a', 'b', 'c'],
		deadline: deadline,
		status: 'DONE',
		title: 'test test',
		timeRecords: [
			{ started: { timezone: 'Europe/Berlin', timestamp: '2024-01-01 00:00:00' }, ended: undefined }
		]
	});

	expect(summary).toEqual(
		new TaskSummary(
			'test',
			'test test',
			['a', 'b', 'c'],
			new ServerDateTime(deadline),
			[{ started: new ServerDateTime(deadline), ended: undefined }],
			'test-a',
			'DONE'
		)
	);
});
