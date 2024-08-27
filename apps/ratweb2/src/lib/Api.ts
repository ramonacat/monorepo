import { merge } from 'lodash-es';
import { CalendarApiClient } from '$lib/api/client/calendar';
import { TaskApiClient } from '$lib/api/client/task';
import { UserApiClient } from '$lib/api/client/user';

export class ApiClient {
	constructor(private token: string) {}

	async query(path: string, options?: RequestInit): Promise<object> {
		const response = await this.call(path, merge(options, { method: 'GET' }));

		return await response.json();
	}

	public async callAction(path: string, actionName: string, body: object) {
		await this.call(path, {
			headers: {
				'X-Action': actionName
			},
			body: JSON.stringify(body)
		});
	}

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

	public user(): UserApiClient {
		return new UserApiClient(this);
	}

	public calendar(): CalendarApiClient {
		return new CalendarApiClient(this);
	}

	public task(): TaskApiClient {
		return new TaskApiClient(this);
	}
}
