export interface PojoUser {
	id: string;
	username: string;
}

export class ServerUserView {
	constructor(id: string, username: string) {
		this.id = id;
		this.username = username;
	}

	id: string;
	username: string;

	toPojo(): PojoUser {
		return { id: this.id, username: this.username };
	}

	static fromPojo(pojo: PojoUser) {
		return new ServerUserView(pojo.id, pojo.username);
	}
}

export interface Session {
	userId: string;
	username: string;
}
