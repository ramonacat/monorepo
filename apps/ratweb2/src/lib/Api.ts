import { merge } from 'lodash-es';
import { DateTime } from 'luxon';
import { TaskUserProfile, WatchedTag } from './TaskUserProfile';
import { type PojoDateTime, ServerDateTime } from '$lib/api/datetime';
import { type PojoTaskSummary, ServerCurrentTaskView, TaskSummary } from '$lib/api/task';
import { EventView } from '$lib/api/calendar';
import { ServerUserView, type Session } from '$lib/api/user';

interface RawUser {
	id: string;
	username: string;
}

export class ApiClient {
	constructor(private token: string) {}

	private async query(path: string, options?: RequestInit): Promise<object> {
		const response = await this.call(path, merge(options, { method: 'GET' }));

		return await response.json();
	}

	private async call(path: string, options: RequestInit | undefined) {
		const response = await fetch(
			(process?.env?.RAS2_SERVICE_URL ?? 'http://localhost:8080/') + path,
			merge(
				{
					method: 'POST',
					headers: {
						'X-User-Token': this.token,
						'Content-Type': 'application/json'
					}
				},
				options ?? {}
			)
		);
		if (!response.ok) {
			throw new Error(
				'Failed to execute query to path: ' + path + ', response: ' + (await response.text())
			);
		}
		return response;
	}

	public async fetchSession(): Promise<Session> {
		return (await this.query('users?action=session')) as Session;
	}

	public async upsertBacklogItem(
		id: string,
		title: string,
		tags: string[],
		deadline: DateTime | undefined,
		assignee: string | undefined
	): Promise<void> {
		await this.call('tasks', {
			body: JSON.stringify({
				id,
				title,
				tags,
				deadline: deadline
					? { timestamp: deadline.toFormat('yyyy-LL-dd HH:mm:ss'), timezone: deadline.zoneName }
					: null,
				assignee: assignee
			}),
			headers: {
				'X-Action': 'upsert:backlog-item'
			}
		});
	}

	async startWork(userId: string, taskId: string) {
		await this.call('tasks', {
			body: JSON.stringify({ userId, taskId }),
			headers: {
				'X-Action': 'start-work'
			}
		});
	}

	async pauseWork(taskId: string) {
		await this.call('tasks', {
			body: JSON.stringify({ taskId }),
			headers: {
				'X-Action': 'pause-work'
			}
		});
	}

	async finishWork(taskId: string, userId: string) {
		await this.call('tasks', {
			body: JSON.stringify({ userId, taskId }),
			headers: {
				'X-Action': 'finish-work'
			}
		});
	}

	async returnToBacklog(taskId: string) {
		await this.call('tasks', {
			body: JSON.stringify({ taskId }),
			headers: {
				'X-Action': 'return-to-backlog'
			}
		});
	}

	async returnToIdea(taskId: string) {
		await this.call('tasks', {
			body: JSON.stringify({ taskId }),
			headers: {
				'X-Action': 'return-to-idea'
			}
		});
	}

	async updateTagsProfile(userId: string, tags: string[]) {
		await this.call('tasks/user-profiles', {
			headers: {
				'X-Action': 'upsert'
			},
			body: JSON.stringify({
				userId,
				watchedTags: tags
			})
		});
	}

	public async getTaskByID(id: string): Promise<TaskSummary> {
		const raw: PojoTaskSummary = (await this.query(`tasks/${id}?action=by-id`)) as PojoTaskSummary;

		return TaskSummary.fromPojo(raw);
	}

	public async findAllUsers() {
		const raw: RawUser[] = (await this.query('users?action=all')) as RawUser[];

		return raw.map((x) => new ServerUserView(x.id, x.username));
	}

	public async findUpcomingTasks(assigneeId: string, limit: number = 100): Promise<TaskSummary[]> {
		const raw: PojoTaskSummary[] = (await this.query(
			'tasks?action=upcoming&limit=' + limit + '&assigneeId=' + assigneeId
		)) as PojoTaskSummary[];

		return raw.map(TaskSummary.fromPojo);
	}

	public async findWatchedTasks(limit: number = 100): Promise<TaskSummary[]> {
		const raw = (await this.query('tasks?action=watched&limit=' + limit)) as PojoTaskSummary[];

		return raw.map(TaskSummary.fromPojo);
	}

	async findIdeas(limit: number = 100) {
		const raw = (await this.query('tasks?action=ideas&limit=' + limit)) as PojoTaskSummary[];

		return raw.map(TaskSummary.fromPojo);
	}

	public async findCurrentTask(): Promise<ServerCurrentTaskView | undefined> {
		const raw = (await this.query('tasks?action=current')) as {
			id: string;
			title: string;
			startTime: PojoDateTime;
			isPaused: boolean;
		} | null;

		return raw
			? new ServerCurrentTaskView(
					raw.id,
					raw.title,
					ServerDateTime.fromPojo(raw.startTime),
					raw.isPaused
				)
			: undefined;
	}

	async findTaskUserProfile() {
		const result = (await this.query('/tasks/user-profiles?action=current')) as {
			userId: string;
			watchedTags: { id: string; name: string }[];
		};

		return new TaskUserProfile(
			result.userId,
			result.watchedTags.map((x) => new WatchedTag(x.id, x.name))
		);
	}

	async findEventsInMonth(year: number, month: number) {
		const result = (await this.query(
			'/events?action=in-month&year=' + year + '&month=' + month
		)) as {
			id: string;
			title: string;
			start: PojoDateTime;
			end: PojoDateTime;
			attendeeUsernames: string[];
		}[];

		return result.map(
			(x) =>
				new EventView(
					x.id,
					x.title,
					ServerDateTime.fromPojo(x.start),
					ServerDateTime.fromPojo(x.end),
					x.attendeeUsernames
				)
		);
	}
}
