import { type Cookies, redirect } from '@sveltejs/kit';
import { ApiClient } from '$lib/Api';
import type { Session } from '$lib/api/user';

export async function ensureAuthenticated(
	cookies: Cookies
): Promise<{ session: Session; apiClient: ApiClient }> {
	const token = cookies.get('token');

	if (!token) {
		redirect(302, '/login');
	}

	const apiClient: ApiClient = new ApiClient(token);
	const session: Session = await apiClient.fetchSession();

	return { session, apiClient };
}
