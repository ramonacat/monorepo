import type { Cookies } from '@sveltejs/kit';

export function getToken(cookies: Cookies): string {
	const token = cookies.get('token');
	if (!token) {
		throw Error('No token was found');
	}

	return token;
}
