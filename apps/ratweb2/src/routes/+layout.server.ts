import { ensureAuthenticated } from '$lib/ensureAuthenticated';

export async function load({ cookies, route }) {
	if (route.id === '/login') {
		return { currentTask: undefined };
	}

	const { apiClient } = await ensureAuthenticated(cookies);

	const currentTask = await apiClient.findCurrentTask();

	return {
		currentTask: currentTask?.toPojo()
	};
}
