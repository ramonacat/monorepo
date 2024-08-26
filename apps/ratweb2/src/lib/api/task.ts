import { type PojoDateTime, ServerDateTime } from '$lib/api/datetime';
import { DateTime } from 'luxon';

export type TaskStatus = 'BACKLOG_ITEM' | 'STARTED' | 'DONE' | 'IDEA';

export interface PojoCurrentTask {
	id: string;
	title: string;
	startTime: PojoDateTime;
	isPaused: boolean;
}

export class ServerCurrentTaskView {
	id: string;
	title: string;
	startTime: ServerDateTime;
	isPaused: boolean;

	constructor(id: string, title: string, startTime: ServerDateTime, isPaused: boolean) {
		this.id = id;
		this.title = title;
		this.startTime = startTime;
		this.isPaused = isPaused;
	}

	public toPojo(): PojoCurrentTask {
		return {
			id: this.id,
			title: this.title,
			startTime: this.startTime?.toPojo(),
			isPaused: this.isPaused
		};
	}

	static fromPojo(currentTask: PojoCurrentTask): ServerCurrentTaskView {
		return new ServerCurrentTaskView(
			currentTask.id,
			currentTask.title,
			ServerDateTime.fromPojo(currentTask.startTime),
			currentTask.isPaused
		);
	}
}

export interface PojoTaskSummary {
	id: string;
	title: string;
	tags: string[];
	deadline: PojoDateTime | undefined;
	assigneeId: string | undefined;
	assigneeName: string | undefined;
	timeRecords: { started: PojoDateTime; ended: PojoDateTime | undefined }[];
	status: TaskStatus;
}

export class TaskSummary {
	id: string;
	title: string;
	tags: string[];
	assigneeId: string | undefined;
	assigneeName: string | undefined;
	deadline: ServerDateTime | undefined;
	timeRecords: { started: ServerDateTime; ended: ServerDateTime | undefined }[];
	status: TaskStatus;

	public toPojo(): PojoTaskSummary {
		return {
			id: this.id,
			title: this.title,
			tags: this.tags,
			deadline: this.deadline ? this.deadline.toPojo() : undefined,
			assigneeId: this.assigneeId,
			assigneeName: this.assigneeName,
			timeRecords: this.timeRecords.map(function (x) {
				return { started: x.started.toPojo(), ended: x.ended ? x.ended.toPojo() : undefined };
			}),
			status: this.status
		};
	}

	public static fromPojo(pojo: PojoTaskSummary) {
		return new TaskSummary(
			pojo.id,
			pojo.title,
			pojo.tags,
			pojo.deadline ? ServerDateTime.fromPojo(pojo.deadline) : undefined,
			pojo.timeRecords.map(function (x) {
				return {
					started: ServerDateTime.fromPojo(x.started),
					ended: x.ended ? ServerDateTime.fromPojo(x.ended) : undefined
				};
			}),
			pojo.assigneeId,
			pojo.assigneeName,
			pojo.status
		);
	}

	public constructor(
		id: string,
		title: string,
		tags: string[],
		deadline: ServerDateTime | undefined,
		timeRecords: {
			started: ServerDateTime;
			ended: ServerDateTime | undefined;
		}[],
		assigneeId: string | undefined,
		assigneeName: string | undefined,
		status: TaskStatus
	) {
		this.id = id;
		this.title = title;
		this.tags = tags;
		this.deadline = deadline;
		this.timeRecords = timeRecords;
		this.assigneeId = assigneeId;
		this.assigneeName = assigneeName;
		this.status = status;
	}

	public getTitle(): string {
		return this.title;
	}

	public getTags(): string[] {
		return this.tags;
	}

	public getDeadline(): DateTime | undefined {
		return this.deadline ? this.deadline.toDateTime() : undefined;
	}

	public getAssigneeId(): string | undefined {
		return this.assigneeId;
	}

	public pastDeadline(): boolean {
		const deadline = this.getDeadline();

		return deadline ? deadline < DateTime.now() : false;
	}

	public getStatus(): TaskStatus {
		return this.status;
	}
}
