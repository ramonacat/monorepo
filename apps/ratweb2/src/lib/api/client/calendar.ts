import type { ApiClient } from '$lib/Api';
import { type PojoDateTime, ServerDateTime } from '$lib/api/datetime';
import { EventView } from '$lib/api/calendar';

export class CalendarApiClient {
	public constructor(private inner: ApiClient) {}

	async findEventsInMonth(year: number, month: number) {
		const result = (await this.inner.query(
			'/events?action=in-month&year=' + year + '&month=' + month
		)) as {
			id: string;
			title: string;
			start: PojoDateTime;
			end: PojoDateTime;
			attendeeUsernames: string[];
		}[];

		return result.map(
			(x) =>
				new EventView(
					x.id,
					x.title,
					ServerDateTime.fromPojo(x.start),
					ServerDateTime.fromPojo(x.end),
					x.attendeeUsernames
				)
		);
	}
}
