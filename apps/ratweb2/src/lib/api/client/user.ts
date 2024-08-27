import type { ApiClient } from '$lib/Api';
import { type PojoUser, ServerUserView, type Session } from '$lib/api/user';

export class UserApiClient {
	public constructor(private inner: ApiClient) {}

	public async fetchSession(): Promise<Session> {
		return (await this.inner.query('users?action=session')) as Session;
	}

	public async findAllUsers() {
		const raw: PojoUser[] = (await this.inner.query('users?action=all')) as PojoUser[];

		return raw.map((x) => new ServerUserView(x.id, x.username));
	}
}
