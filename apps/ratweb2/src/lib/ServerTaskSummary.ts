import { DateTime } from 'luxon';
import { ServerDateTime, type TaskStatus } from '$lib/Api';


export interface PojoDateTime {
	timestamp: string;
	timezone: string;
}

export interface PojoTaskSummary {
	id: string;
	title: string;
	tags: string[];
	deadline: PojoDateTime | undefined;
	assigneeId: string | undefined;
	timeRecords: { started: PojoDateTime; ended: PojoDateTime | undefined }[];
	status: TaskStatus;
}

export class ServerTaskSummary {
	id: string;
	title: string;
	tags: string[];
	assigneeId: string | undefined;
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
			timeRecords: this.timeRecords.map(function (x) {
				return { started: x.started.toPojo(), ended: x.ended ? x.ended.toPojo() : undefined };
			}),
			status: this.status
		};
	}

	public static fromPojo(pojo: PojoTaskSummary) {
		return new ServerTaskSummary(
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
			pojo.status
		);
	}

	constructor(
		id: string,
		title: string,
		tags: string[],
		deadline: ServerDateTime | undefined,
		timeRecords: {
			started: ServerDateTime;
			ended: ServerDateTime | undefined;
		}[],
		assignee: string | undefined,
		status: TaskStatus
	) {
		this.id = id;
		this.title = title;
		this.tags = tags;
		this.deadline = deadline;
		this.timeRecords = timeRecords;
		this.assigneeId = assignee;
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
