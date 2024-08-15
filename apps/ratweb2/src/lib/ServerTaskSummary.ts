import { DateTime } from 'luxon';
import { ServerDateTime } from '$lib/Api';

export interface PojoDateTime {
	timestamp: string;
	timezone: string;
}

export interface PojoTaskSummary {
	id: string;
	title: string;
	tags: string[];
	deadline: PojoDateTime | undefined;
	timeRecords: { started: PojoDateTime; ended: PojoDateTime | undefined }[];
}

export class ServerTaskSummary {
	id: string;
	title: string;
	tags: string[];
	deadline: ServerDateTime | undefined;
	timeRecords: { started: ServerDateTime; ended: ServerDateTime | undefined }[];

	public toPojo(): PojoTaskSummary {
		return {
			id: this.id,
			title: this.title,
			tags: this.tags,
			deadline: this.deadline ? this.deadline.toPojo() : undefined,
			timeRecords: this.timeRecords.map(function (x) {
				return { started: x.started.toPojo(), ended: x.ended ? x.ended.toPojo() : undefined };
			})
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
			})
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
		}[]
	) {
		this.id = id;
		this.title = title;
		this.tags = tags;
		this.deadline = deadline;
		this.timeRecords = timeRecords;
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

	public pastDeadline(): boolean {
		const deadline = this.getDeadline();

		return deadline ? deadline < DateTime.now() : false;
	}
}
