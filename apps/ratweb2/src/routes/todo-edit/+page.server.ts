import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import type { Actions } from '@sveltejs/kit';
import { DateTime } from 'luxon';

export async function load({ url, cookies }) {
	const { apiClient } = await ensureAuthenticated(cookies);
	const taskId = url.searchParams.get('task-id') as string;

	const rawTask = await apiClient.getTaskByID(taskId);
	console.log(rawTask);
	const task = rawTask.toPojo();
	console.log(task);
	return {
		task,
		allUsers: (await apiClient.findAllUsers()).map((x) => x.toPojo())
	};
}

export const actions: Actions = {
	default: async function ({ request, cookies, url }) {
		const { apiClient } = await ensureAuthenticated(cookies);
		const data = await request.formData();
		const title = data.get('title');
		const rawTags = data.get('tags');
		const tags = typeof rawTags !== 'string' ? [] : JSON.parse(rawTags.toString());
		// TODO this is a hack, we should use the timezone stored in user's profile
		const deadlineDate = data.get('deadline-date');
		const deadlineTime = (data.get('deadline-time') ?? '00:00') + ':00';
		const deadline = deadlineDate
			? DateTime.fromISO(deadlineDate + 'T' + deadlineTime + '+00:00')
			: undefined;
		const assignee = data.get('assignee');

		try {
			await apiClient.upsertBacklogItem(
				url.searchParams.get('task-id') as string,
				title as string,
				tags,
				deadline,
				assignee as string | undefined
			);
		} catch {
			return { failure: true };
		}

		return { success: true };
	}
};
