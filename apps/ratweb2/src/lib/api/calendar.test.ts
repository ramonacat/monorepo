import { expect, test } from 'vitest';
import { EventView } from '$lib/api/calendar';
import { ServerDateTime } from '$lib/api/datetime';

test('can create EventView from POJO', function () {
	const object = EventView.fromPojo({
		id: 'test',
		title: 'this is a title',
		attendeeUsernames: ['a', 'b', 'c'],
		start: {
			timezone: 'Europe/Berlin',
			timestamp: '2024-04-05 00:00:00'
		},
		end: {
			timezone: 'Europe/Berlin',
			timestamp: '2024-04-05 00:06:00'
		}
	});

	expect(object).toEqual(
		new EventView(
			'test',
			'this is a title',
			new ServerDateTime('2024-04-05 00:00:00', 'Europe/Berlin'),
			new ServerDateTime('2024-04-05 00:06:00', 'Europe/Berlin'),
			['a', 'b', 'c']
		)
	);
});
