import { expect, test } from 'vitest';
import { DateTime, IANAZone } from 'luxon';
import { ServerDateTime } from '$lib/api/datetime';

test('can convert ServerDateTime to Luxon DateTime', function () {
	const serverDateTime = ServerDateTime.fromPojo({
		timestamp: '2024-01-01 05:00:00',
		timezone: 'Europe/Warsaw'
	});

	expect(serverDateTime.toDateTime()).toEqual(
		DateTime.fromObject(
			{
				year: 2024,
				month: 1,
				day: 1,
				hour: 5,
				minute: 0,
				second: 0
			},
			{ zone: IANAZone.create('Europe/Warsaw') }
		)
	);
});
