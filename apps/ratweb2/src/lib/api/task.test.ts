import { expect, test } from 'vitest';
import { ServerDateTime } from '$lib/api/datetime';
import { ServerCurrentTaskView, TaskSummary } from '$lib/api/task';

test('can create summary from pojo', function () {
	const deadline = {
		timestamp: '2024-01-01 00:00:00',
		timezone: 'Europe/Berlin'
	};
	const summary = TaskSummary.fromPojo({
		id: 'test',
		assigneeId: 'test-a',
		assigneeName: 'Test A.',
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
			ServerDateTime.fromPojo(deadline),
			[{ started: ServerDateTime.fromPojo(deadline), ended: undefined }],
			'test-a',
			'Test A.',
			'DONE'
		)
	);
});

test('can create current task view from pojo', function () {
	const summary = ServerCurrentTaskView.fromPojo({
		id: 'test',
		title: 'test test',
		startTime: {
			timestamp: '2024-01-01 12:00:00',
			timezone: 'Europe/Berlin'
		},
		isPaused: true
	});

	expect(summary).toEqual(
		new ServerCurrentTaskView(
			'test',
			'test test',
			new ServerDateTime('2024-01-01 12:00:00', 'Europe/Berlin'),
			true
		)
	);
});
