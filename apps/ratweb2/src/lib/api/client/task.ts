import type { ApiClient } from '$lib/Api';
import { TaskUserProfile, WatchedTag } from '$lib/TaskUserProfile';
import {
	type PojoCurrentTask,
	type PojoTaskSummary,
	ServerCurrentTaskView,
	TaskSummary
} from '$lib/api/task';
import { DateTime } from 'luxon';

export class TaskApiClient {
	public constructor(private inner: ApiClient) {}

	async findTaskUserProfile() {
		const result = (await this.inner.query('/tasks/user-profiles?action=current')) as {
			userId: string;
			watchedTags: { id: string; name: string }[];
		};

		return new TaskUserProfile(
			result.userId,
			result.watchedTags.map((x) => new WatchedTag(x.id, x.name))
		);
	}

	async updateTagsProfile(userId: string, tags: string[]) {
		await this.inner.callAction('tasks/user-profiles', 'upsert', {
			userId,
			watchedTags: tags
		});
	}

	public async upsertBacklogItem(
		id: string,
		title: string,
		tags: string[],
		deadline: DateTime | undefined,
		assignee: string | undefined
	): Promise<void> {
		await this.inner.callAction('tasks', 'upsert:backlog-item', {
			id,
			title,
			tags,
			deadline: deadline
				? { timestamp: deadline.toFormat('yyyy-LL-dd HH:mm:ss'), timezone: deadline.zoneName }
				: null,
			assignee: assignee
		});
	}

	public async findCurrentTask(): Promise<ServerCurrentTaskView | undefined> {
		const raw = (await this.inner.query('tasks?action=current')) as PojoCurrentTask | null;

		return raw ? ServerCurrentTaskView.fromPojo(raw) : undefined;
	}

	public async findUpcomingTasks(assigneeId: string, limit: number = 100): Promise<TaskSummary[]> {
		const raw: PojoTaskSummary[] = (await this.inner.query(
			'tasks?action=upcoming&limit=' + limit + '&assigneeId=' + assigneeId
		)) as PojoTaskSummary[];

		return raw.map(TaskSummary.fromPojo);
	}

	public async findWatchedTasks(limit: number = 100): Promise<TaskSummary[]> {
		const raw = (await this.inner.query(
			'tasks?action=watched&limit=' + limit
		)) as PojoTaskSummary[];

		return raw.map(TaskSummary.fromPojo);
	}

	async findIdeas(limit: number = 100) {
		const raw = (await this.inner.query('tasks?action=ideas&limit=' + limit)) as PojoTaskSummary[];

		return raw.map(TaskSummary.fromPojo);
	}

	public async getTaskByID(id: string): Promise<TaskSummary> {
		const raw: PojoTaskSummary = (await this.inner.query(
			`tasks/${id}?action=by-id`
		)) as PojoTaskSummary;

		return TaskSummary.fromPojo(raw);
	}

	async startWork(userId: string, taskId: string) {
		await this.inner.callAction('tasks', 'start-work', { taskId });
	}

	async pauseWork(taskId: string) {
		await this.inner.callAction('tasks', 'pause-work', { taskId });
	}

	async finishWork(taskId: string, userId: string) {
		await this.inner.callAction('tasks', 'finish-work', { taskId, userId });
	}

	async returnToBacklog(taskId: string) {
		await this.inner.callAction('tasks', 'return-to-backlog', { taskId });
	}

	async returnToIdea(taskId: string) {
		await this.inner.callAction('tasks', 'return-to-idea', { taskId });
	}
}
