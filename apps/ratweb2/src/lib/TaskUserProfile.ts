export class WatchedTag {
	id: string;
	name: string;

	public constructor(id: string, name: string) {
		this.id = id;
		this.name = name;
	}

	toPojo(): PojoWatchedTag {
		return {
			id: this.id,
			name: this.name
		};
	}

	static fromPojo(x: PojoWatchedTag) {
		return new WatchedTag(x.id, x.name);
	}
}

interface PojoWatchedTag {
	id: string;
	name: string;
}

interface PojoTaskUserProfile {
	userId: string;
	watchedTags: PojoWatchedTag[];
}

export class TaskUserProfile {
	userId: string;
	watchedTags: WatchedTag[];

	public constructor(userId: string, watchedTags: WatchedTag[]) {
		this.userId = userId;
		this.watchedTags = watchedTags;
	}

	toPojo(): PojoTaskUserProfile {
		return {
			userId: this.userId,
			watchedTags: this.watchedTags.map((x) => x.toPojo())
		};
	}

	static fromPojo(watchedTasks: PojoTaskUserProfile) {
		return new TaskUserProfile(
			watchedTasks.userId,
			watchedTasks.watchedTags.map((x) => WatchedTag.fromPojo(x))
		);
	}
}
