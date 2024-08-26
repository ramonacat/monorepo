import { type Actions, fail } from '@sveltejs/kit';
import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import { DateTime } from 'luxon';

export async function load({ cookies }) {
	const { apiClient, session } = await ensureAuthenticated(cookies);

	const upcomingTasks = await apiClient.findUpcomingTasks(session.userId);
	const watchedTasks = await apiClient.findWatchedTasks();
	const allUsers = await apiClient.findAllUsers();
	const ideas = await apiClient.findIdeas();

	return {
		upcomingTasks: upcomingTasks.map((x) => x.toPojo()),
		watchedTasks: watchedTasks.map((x) => x.toPojo()),
		allUsers: allUsers.map((x) => x.toPojo()),
		ideas: ideas.map((x) => x.toPojo())
	};
}

export const actions = {
	start_task: async ({ request, cookies }) => {
		const { session, apiClient } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');
		const userId = session.userId;
		await apiClient.startWork(userId as string, taskId as string);
	},
	pause_task: async ({ request, cookies }) => {
		const { apiClient } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');
		await apiClient.pauseWork(taskId as string);
	},
	finish_task: async ({ request, cookies }) => {
		const { session, apiClient } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');

		await apiClient.finishWork(taskId as string, session.userId as string);
	},
	return_to_backlog: async ({ request, cookies }) => {
		const { apiClient } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id');
		await apiClient.returnToBacklog(taskId as string);
	},
	return_to_idea: async ({ request, cookies }) => {
		const { apiClient } = await ensureAuthenticated(cookies);

		const data = await request.formData();
		const taskId = data.get('task-id') as string;

		await apiClient.returnToIdea(taskId);
	},
	create_backlog_item: async ({ request, cookies }) => {
		await ensureAuthenticated(cookies);

		const data = await request.formData();
		const title = data.get('title');
		const rawTags = data.get('tags');
		const tags = typeof rawTags !== 'string' ? [] : JSON.parse(rawTags.toString());

		const deadlineDate = data.get('deadline-date');
		const deadlineTime = data.get('deadline-time') ?? '00:00:00';
		const deadline = deadlineDate
			? DateTime.fromJSDate(new Date(deadlineDate + 'T' + deadlineTime + '+00:00'))
			: null;
		const assignee = data.get('assignee') !== '' ? data.get('assignee') : null;

		const id = crypto.randomUUID();
		// FIXME use the API client here
		const response = await fetch(
			(process?.env?.RAS2_SERVICE_URL ?? 'http://localhost:8080/') + 'tasks',
			{
				method: 'POST',
				body: JSON.stringify({
					id,
					title,
					tags,
					deadline: deadline
						? {
								timezone: 'Europe/Berlin', // FIXME take this from the user profile!
								timestamp: deadline.toFormat('yyyy-LL-dd HH:mm:ss')
							}
						: null,
					assignee
				}),
				headers: {
					'X-Action': 'upsert:backlog-item',
					'Content-Type': 'application/json',
					'X-User-Token': cookies.get('token') as string
				}
			}
		);

		if (response.ok) {
			return {
				currentTab: 0,
				id: id,
				success: true
			};
		} else {
			return fail(response.status, { currentTab: 0, failed: true });
		}
	},
	create_idea: async ({ request, cookies }) => {
		await ensureAuthenticated(cookies);

		const data = await request.formData();
		const title = data.get('title');
		const rawTags = data.get('tags');
		const tags = typeof rawTags !== 'string' ? [] : JSON.parse(rawTags.toString());

		const id = crypto.randomUUID();
		const response = await fetch(
			// FIXME use the API client here
			(process?.env?.RAS2_SERVICE_URL ?? 'http://localhost:8080/') + 'tasks',
			{
				method: 'POST',
				body: JSON.stringify({
					id,
					title,
					tags
				}),
				headers: {
					'X-Action': 'upsert:idea',
					'Content-Type': 'application/json',
					'X-User-Token': cookies.get('token') as string
				}
			}
		);

		if (response.ok) {
			return {
				currentTab: 2,
				id: id,
				success: true
			};
		} else {
			return fail(response.status, { currentTab: 2, failed: true });
		}
	},
	create_event: async ({ request, cookies }) => {
		await ensureAuthenticated(cookies);

		const data = await request.formData();
		const title = data.get('title');
		const startDate = data.get('start-date');
		const startTime = data.get('start-time') ?? '00:00:00';
		const start = startDate
			? DateTime.fromJSDate(new Date(startDate + 'T' + startTime + '+00:00'))
			: null;
		const endDate = data.get('start-date');
		const endTime = data.get('start-time') ?? '00:00:00';
		const end = endDate ? DateTime.fromJSDate(new Date(endDate + 'T' + endTime + '+00:00')) : null;
		const attendees = data.get('attendees') ? JSON.parse(data.get('attendees') as string) : null;

		const id = crypto.randomUUID();
		const response = await fetch(
			// FIXME use the API client here
			(process?.env?.RAS2_SERVICE_URL ?? 'http://localhost:8080/') + 'events',
			{
				method: 'POST',
				body: JSON.stringify({
					id,
					title,
					startTime: start
						? {
								timezone: 'Europe/Berlin', // FIXME take this from the user profile!
								timestamp: start.toFormat('yyyy-LL-dd HH:mm:ss')
							}
						: null,
					endTime: end
						? {
								timezone: 'Europe/Berlin', // FIXME take this from the user profile!
								timestamp: end.toFormat('yyyy-LL-dd HH:mm:ss')
							}
						: null,
					attendees
				}),
				headers: {
					'X-Action': 'upsert',
					'Content-Type': 'application/json',
					'X-User-Token': cookies.get('token') as string
				}
			}
		);

		if (response.ok) {
			return {
				currentTab: 1,
				id: id,
				success: true
			};
		} else {
			return fail(response.status, { currentTab: 1, failed: true });
		}
	}
} satisfies Actions;
