import { merge } from 'lodash-es';
import { DateTime } from 'luxon';
import type { Session } from '$lib/Session';
import { type PojoDateTime, ServerTaskSummary } from '$lib/ServerTaskSummary';
import { ServerCurrentTaskView } from '$lib/ServerCurrentTaskView';
import { ServerUserView } from '$lib/ServerUserView';
import { TaskUserProfile, WatchedTag } from './TaskUserProfile';
import { EventView } from '$lib/EventView';

interface RawServerDateTime {
	timestamp: string;
	timezone: string;
}

interface RawTask {
	id: string;
	title: string;
	tags: string[];
	deadline: RawServerDateTime | undefined;
	timeRecords: { started: RawServerDateTime; ended: RawServerDateTime | undefined }[];
	assigneeId: string | undefined;
}

export class ServerDateTime {
	private timestamp: string;
	private timezone: string;

	public constructor(raw: RawServerDateTime) {
		this.timestamp = raw.timestamp;
		this.timezone = raw.timezone;
	}

	public toDateTime(): DateTime {
		return DateTime.fromFormat(this.timestamp, 'yyyy-MM-dd HH:mm:ss', { zone: this.timezone });
	}

	public toPojo() {
		return { timestamp: this.timestamp, timezone: this.timezone };
	}

	public static fromPojo(deadline: PojoDateTime) {
		return new ServerDateTime({ timestamp: deadline.timestamp, timezone: deadline.timezone });
	}
}

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

	// FIXME make everything call through more specific APIs and make this private
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

	async updateTagsProfile(userId: string, tags: string[]) {
		await this.call('tasks/user-profiles', {
			body: JSON.stringify({
				userId,
				watchedTags: tags
			})
		});
	}

	public async getTaskByID(id: string): Promise<ServerTaskSummary> {
		const raw: RawTask = (await this.query(`tasks/${id}`)) as RawTask;

		return new ServerTaskSummary(
			raw.id,
			raw.title,
			raw.tags,
			raw.deadline ? new ServerDateTime(raw.deadline) : undefined,
			raw.timeRecords.map(function (x) {
				return {
					started: new ServerDateTime(x.started),
					ended: x.ended ? new ServerDateTime(x.ended) : undefined
				};
			}),
			raw.assigneeId
		);
	}

	public async findAllUsers() {
		const raw: RawUser[] = (await this.query('users?action=all')) as RawUser[];

		return raw.map((x) => new ServerUserView(x.id, x.username));
	}

	public async findUpcomingTasks(
		assigneeId: string,
		limit: number = 10
	): Promise<ServerTaskSummary[]> {
		const raw: RawTask[] = (await this.query(
			'tasks?action=upcoming&limit=' + limit + '&assigneeId=' + assigneeId
		)) as RawTask[];

		return raw.map(this.rawTaskToObject);
	}

	public async findWatchedTasks(limit: number = 10): Promise<ServerTaskSummary[]> {
		const raw = (await this.query('tasks?action=watched&limit=' + limit)) as RawTask[];

		return raw.map(this.rawTaskToObject);
	}

	public async findCurrentTask(): Promise<ServerCurrentTaskView | undefined> {
		const raw = (await this.query('tasks?action=current')) as {
			id: string;
			title: string;
			startTime: RawServerDateTime;
			isPaused: boolean;
		} | null;

		return raw
			? new ServerCurrentTaskView(
					raw.id,
					raw.title,
					new ServerDateTime(raw.startTime),
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
			start: RawServerDateTime;
			end: RawServerDateTime;
			attendeeUsernames: string[];
		}[];

		return result.map(
			(x) =>
				new EventView(
					x.id,
					x.title,
					new ServerDateTime(x.start),
					new ServerDateTime(x.end),
					x.attendeeUsernames
				)
		);
	}

	private rawTaskToObject(raw: RawTask): ServerTaskSummary {
		return new ServerTaskSummary(
			raw.id,
			raw.title,
			raw.tags,
			raw.deadline ? new ServerDateTime(raw.deadline) : undefined,
			raw.timeRecords.map(function (x) {
				return {
					started: new ServerDateTime(x.started),
					ended: x.ended ? new ServerDateTime(x.ended) : undefined
				};
			}),
			raw.assigneeId
		);
	}
}
