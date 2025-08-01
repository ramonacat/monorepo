import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import type { Actions, Cookies } from '@sveltejs/kit';

export async function load({ cookies }: {cookies: Cookies}) {
	const { apiClient } = await ensureAuthenticated(cookies);

	return {
		allUsers: (await apiClient.user().findAllUsers()).map((x) => x.toPojo())
	};
}

export const actions: Actions = {
	default: async function ({ request, cookies }) {
		const { apiClient } = await ensureAuthenticated(cookies);
		const data = await request.formData();

		const name = data.get('name') as string;

		const rawTags = data.get('tags');
		const tags = typeof rawTags === 'string' ? JSON.parse(rawTags.toString()) : [];

		const rawAssignees = data.get('assignees');
		const assignees =
			typeof rawAssignees === 'string' ? JSON.parse(data.get('assignees') as string) : [];

		try {
			await apiClient.task().upsertFilter(name, tags, assignees);
		} catch {
			return { failure: true };
		}

		return { success: true };
	}
};
