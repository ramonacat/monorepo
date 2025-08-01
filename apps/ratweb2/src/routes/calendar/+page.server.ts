import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import { DateTime } from 'luxon';
import { type Cookies } from '@sveltejs/kit';

export async function load({ cookies, url }: {cookies: Cookies, url: URL}) {
	const { apiClient } = await ensureAuthenticated(cookies);
	const now = DateTime.now();
	const year = url.searchParams.get('year') ?? now.year;
	const month = url.searchParams.get('month') ?? now.month;

	return {
		events: (await apiClient.calendar().findEventsInMonth(year as number, month as number)).map(
			(x) => x.toPojo()
		)
	};
}
