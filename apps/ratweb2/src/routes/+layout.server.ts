import { ensureAuthenticated } from '$lib/ensureAuthenticated';

export async function load({ cookies }) {
	const { apiClient } = await ensureAuthenticated(cookies);

	const currentTask = await apiClient.findCurrentTask();

	return {
		currentTask: currentTask?.toPojo(),
	};
}