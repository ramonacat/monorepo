import { merge } from 'lodash-es';

export default class ApiClient {
	constructor(private token: string) {}

	public async query(path: string, options?: RequestInit): Promise<object> {
		const response = await this.call(path, options);

		return await response.json();
	}

	public async call(path: string, options: RequestInit | undefined) {
		const response = await fetch(
			'http://localhost:8080/' + path,
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
			throw new Error('Failed to execute query to path: ' + path);
		}
		return response;
	}
}
