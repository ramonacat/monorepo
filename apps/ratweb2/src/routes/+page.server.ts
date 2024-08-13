import { type Actions, fail } from '@sveltejs/kit';
import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import { ApiClient } from '$lib/Api';

export async function load({ cookies }) {
	const { apiClient, session } = await ensureAuthenticated(cookies);

	const upcomingTasks = await apiClient.findUpcomingTasks(session.userId);
	const watchedTasks = await apiClient.findWatchedTasks();
	const currentTask = await apiClient.findCurrentTask();

	return {
		upcomingTasks: upcomingTasks.map((x) => x.toPojo()),
		watchedTasks: watchedTasks.map((x) => x.toPojo()),
		currentTask: currentTask?.toPojo()
	};
}

async function sendCommand(token: string, name: string, data: object) {
	const result = await new ApiClient(token).call('tasks', {
		method: 'POST',
		body: JSON.stringify(data),
		headers: {
			'X-Action': name
		}
	});
	if (!result.ok) {
		throw new Error('Failed to execute command');
	}
}

export const actions = {
	start_task: async ({ request, cookies }) => {
		const { session } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');
		const userId = session.userId;
		await sendCommand(cookies.get('token') as string, 'start-work', { taskId: taskId, userId });
	},
	pause_task: async ({ request, cookies }) => {
		await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');
		await sendCommand(cookies.get('token') as string, 'pause-work', { taskId: taskId });
	},
	finish_task: async ({ request, cookies }) => {
		const { session } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');

		await sendCommand(cookies.get('token') as string, 'finish-work', {
			taskId,
			userId: session.userId
		});
	},
	return_to_backlog: async ({ request, cookies }) => {
		await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');
		await sendCommand(cookies.get('token') as string, 'return-to-backlog', { taskId: taskId });
	},
	create_backlog_item: async ({ request, cookies }) => {
		await ensureAuthenticated(cookies);

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
