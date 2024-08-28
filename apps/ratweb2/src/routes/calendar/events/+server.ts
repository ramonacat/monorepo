import type { RequestHandler } from './$types';
import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import { DateTime } from 'luxon';

export const GET: RequestHandler = async ({ url, cookies }) => {
	const { apiClient } = await ensureAuthenticated(cookies);
	const now = DateTime.now();
	const year = url.searchParams.get('year') ?? now.year;
	const month = url.searchParams.get('month') ?? now.month;

	const result = (
		await apiClient.calendar().findEventsInMonth(year as number, month as number)
	).map((x) => x.toPojo());

	return new Response(JSON.stringify(result));
};
