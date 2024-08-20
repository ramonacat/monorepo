import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import type { Actions } from '@sveltejs/kit';

export async function load({ cookies }) {
	const { apiClient, session } = await ensureAuthenticated(cookies);

	try {
		const userProfile = await apiClient.findTaskUserProfile();

		return {
			userProfile: userProfile?.toPojo()
		};
	} catch(e) {
		console.log('No profile was found for the user, allowing creation...', e)

		return {
			userProfile: {
				userId: session.userId,
				watchedTags: []
			}
		}
	}
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
