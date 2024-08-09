import { type Actions, fail, redirect } from '@sveltejs/kit';
import { DateTime } from 'luxon';

export async function load({ cookies }) {
	const token = cookies.get('token');

	if (!token) {
		return redirect(302, '/login');
	}

	const upcomingTasks = await fetch('http://localhost:8080/tasks?upcoming', {
		headers: {
			'X-User-Token': token
		}
	});
	if (upcomingTasks.ok) {
		return {
			upcomingTasks: (await upcomingTasks.json()).map(
				(x: { deadline: { timestamp: number }; title: string; tags: string }) => {
					console.log(x.deadline);
					const deadline = DateTime.fromSeconds(x.deadline.timestamp);
					return {
						title: x.title,
						tags: x.tags,
						deadline: deadline.toISO(), // TODO handle timezone!
						pastDeadline: deadline < DateTime.now()
					};
				}
			)
		};
	}
}

export const actions = {
	create_backlog_item: async ({ request, cookies }) => {
		const data = await request.formData();
		const title = data.get('title');
		const rawTags = data.get('tags');
		const tags = typeof rawTags !== 'string' ? [] : JSON.parse(rawTags.toString());
		// TODO this is a hack, we should use the timezone stored in user's profile
		const deadlineDate = data.get('deadline-date');
		const deadlineTime = data.get('deadline-time') ?? '00:00:00';
		const deadline =
			deadlineDate === null ? null : new Date(deadlineDate + 'T' + deadlineTime + '+00:00');

		const id = crypto.randomUUID();
		const response = await fetch('http://localhost:8080/tasks', {
			method: 'POST',
			body: JSON.stringify({ id, title, tags, deadline, assignee: null }),
			headers: {
				'X-Action': 'upsert:backlog-item',
				'Content-Type': 'application/json',
				'X-User-Token': cookies.get('token') as string
			}
		});

		if (response.ok) {
			return { id: id, success: true };
		} else {
			return fail(response.status, { failed: true });
		}
	}
} satisfies Actions;
