import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import type { Cookies, RouteDefinition } from '@sveltejs/kit';

export async function load({ cookies, route }: {cookies: Cookies, route: RouteDefinition}) {
	if (route.id === '/login') {
		return { currentTask: undefined };
	}

	const { apiClient } = await ensureAuthenticated(cookies);

	const currentTask = await apiClient.task().findCurrentTask();

	return {
		currentTask: currentTask?.toPojo()
	};
}
