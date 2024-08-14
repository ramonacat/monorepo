import { type Actions, fail, redirect } from '@sveltejs/kit';
export const actions = {
	default: async ({ request, cookies }) => {
		const data = await request.formData();

		const username = data.get('username');
		const response = await fetch((process?.env?.RAS2_SERVICE_URL ?? 'http://localhost:8080/') + 'users', {
			method: 'POST',
			body: JSON.stringify({ username }),
			headers: {
				'X-Action': 'login',
				'Content-Type': 'application/json'
			}
		});

		if (response.ok) {
			const token = await response.json();

			cookies.set('token', token.token, { path: '/' });

			return redirect(302, '/');
		} else {
			return fail(response.status, { failed: true });
		}
	}
} satisfies Actions;
