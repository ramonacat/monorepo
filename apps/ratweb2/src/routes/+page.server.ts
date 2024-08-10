import { type Actions, fail, redirect } from '@sveltejs/kit';
import { DateTime } from 'luxon';
import ApiClient from '$lib/ApiClient';
import type { ServerDateTime } from '$lib/ServerDateTime';

interface ServerTaskView {
	id: string;
	title: string;
	deadline: {
		timestamp: number;
		timezone: string;
	};
	assigneeName: string;
	tags: string[];
	timeRecords: {started:ServerDateTime, ended:ServerDateTime|undefined}[]
}

interface Session {
	userId: string;
	username: string;
}

export async function load({ cookies }) {
	const token = cookies.get('token');

	if (!token) {
		return redirect(302, '/login');
	}

	const apiClient: ApiClient = new ApiClient(token);

	const session: Session = (await apiClient.query('users?action=session')) as Session;

	const upcomingTasks: ServerTaskView[] = (await apiClient.query(
		'tasks?action=upcoming&limit=10&assigneeId=' + session.userId
	)) as ServerTaskView[];
	const watchedTasks: ServerTaskView[] = (await apiClient.query(
		'tasks?action=watched&limit=10'
	)) as ServerTaskView[];
	const currentTask: ServerTaskView|undefined = (await apiClient.query('tasks?action=current')) as ServerTaskView|undefined;

	function convertApiTask() {
		return (x: ServerTaskView) => {
			const deadline = x.deadline === null ? null : DateTime.fromSeconds(x.deadline.timestamp);
			return {
				id: x.id,
				title: x.title,
				tags: x.tags,
				deadline: deadline?.toISO(), // TODO handle timezone!
				pastDeadline: deadline === null ? false : deadline < DateTime.now(),
				timeRecords: x.timeRecords
			};
		};
	}

	return {
		upcomingTasks: upcomingTasks.map(convertApiTask()),
		watchedTasks: watchedTasks.map(convertApiTask()),
		currentTask: currentTask === undefined ? null : convertApiTask()(currentTask)
	};
}

export const actions = {
	start_task: async ({ request, cookies }) => {
		const data = await request.formData();
		const id = data.get('task-id');

		await new ApiClient(cookies.get('token') as string).call('tasks', {
			method: 'POST',
			body: JSON.stringify({ taskId: id }),
			headers: {
				'X-Action': 'start-work'
			}
		});
	},
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
