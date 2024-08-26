import { ServerDateTime } from '$lib/Api';
import type { PojoDateTime } from '$lib/TaskSummary';

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
