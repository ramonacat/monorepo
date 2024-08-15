import { merge } from 'lodash-es';
import { DateTime } from 'luxon';
import type { Session } from '$lib/Session';
import { type PojoDateTime, ServerTaskSummary } from '$lib/ServerTaskSummary';
import { ServerCurrentTaskView } from '$lib/ServerCurrentTaskView';

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
}

export class ServerDateTime {
	private timestamp: string;
	private timezone: string;

	public constructor(raw: RawServerDateTime) {
		this.timestamp = raw.timestamp;
		this.timezone = raw.timezone;
	}

	public toDateTime(): DateTime {
		return DateTime.fromFormat(this.timestamp, 'yyyy-MM-dd HH:mm:ss', {zone: this.timezone});
	}

	public toPojo() {
		return { timestamp: this.timestamp, timezone: this.timezone };
	}

	public static fromPojo(deadline: PojoDateTime) {
		return new ServerDateTime({ timestamp: deadline.timestamp, timezone: deadline.timezone });
	}
}

export class ApiClient {
	constructor(private token: string) {}

	private async query(path: string, options?: RequestInit): Promise<object> {
		const response = await this.call(path, options);

		return await response.json();
	}

	// FIXME make everything call through more specific APIs and make this private
	public async call(path: string, options: RequestInit | undefined) {
		const response = await fetch(
			(process?.env?.RAS2_SERVICE_URL ?? 'http://localhost:8080/') + path,
			merge(
				{
					headers: {
						'X-User-Token': this.token,
						'Content-Type': 'application/json'
					}
				},
				options ?? {}
			)
		);
		if (!response.ok) {
			throw new Error('Failed to execute query to path: ' + path + ', response: ' + (await response.text()));
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
		deadline: DateTime | null
	): Promise<void> {
		await this.call('tasks', {
			method: 'POST',
			body: JSON.stringify({
				id,
				title,
				tags,
				deadline: { timestamp: deadline?.toString(), timezone: deadline?.zoneName },
				assignee: null
			}),
			headers: {
				'X-Action': 'upsert:backlog-item',
				'Content-Type': 'application/json'
			}
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
			})
		);
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
			})
		);
	}
}
