import type { Cookies } from '@sveltejs/kit';
import type { Session } from '$lib/Session';
import type ApiClient from '$lib/ApiClient';

export function getToken(cookies: Cookies): string {
	const token = cookies.get('token');
	if(!token) {
		throw Error('No token was found');
	}

	return token;
}

export async function fetchSession(apiClient: ApiClient): Promise<Session> {
	return (await apiClient.query('users?action=session')) as Session;
}