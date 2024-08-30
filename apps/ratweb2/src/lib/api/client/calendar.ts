import type { ApiClient } from '$lib/Api';
import { EventView, type PojoEventView } from '$lib/api/calendar';

export class CalendarApiClient {
	public constructor(private inner: ApiClient) {}

	async findEventsInMonth(year: number, month: number) {
		const result = (await this.inner.query(
			'/events?action=in-month&year=' + year + '&month=' + month
		)) as PojoEventView[];

		return result.map((x) => EventView.fromPojo(x));
	}
}
