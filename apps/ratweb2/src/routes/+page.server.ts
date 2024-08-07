import { type Actions, fail } from '@sveltejs/kit';

export const actions = {
	create_backlog_item: async ({ request }) => {
		const data = await request.formData();
		const title = data.get('title');
		const rawTags = data.get('tags');
		const tags = typeof rawTags !== 'string' ? [] : JSON.parse(rawTags.toString());
		// const deadline = data.get('deadline');

		const id = crypto.randomUUID();
		const response = await fetch('http://localhost:8080/tasks', {
			method: 'POST',
			// todo also send the deadline here!
			body: JSON.stringify({ id, title, tags, assignee: null }),
			headers: {
				'X-Action': 'upsert:backlog-item',
				'Content-Type': 'application/json'
			}
		});

		if (response.ok) {
			return { id: id, success: true };
		} else {
			return fail(response.status, { failed: true });
		}
	}
} satisfies Actions;
