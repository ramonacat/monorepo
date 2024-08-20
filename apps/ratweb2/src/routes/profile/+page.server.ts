import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import type { Actions } from '@sveltejs/kit';

export async function load({ cookies }) {
	const { apiClient } = await ensureAuthenticated(cookies);

	const userProfile = await apiClient.findTaskUserProfile();

	return {
		userProfile: userProfile?.toPojo()
	};
}

export const actions: Actions = {
	edit_tasks_profile: async function ({ request, cookies }) {
		const { apiClient, session } = await ensureAuthenticated(cookies);
		const data = await request.formData();
		const rawTags = data.get('watchedTags');
		const tags = typeof rawTags !== 'string' ? [] : JSON.parse(rawTags.toString());

		await apiClient.updateTagsProfile(session.userId, tags);
	}
};
