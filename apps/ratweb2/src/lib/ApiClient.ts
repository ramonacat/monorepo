import { merge } from 'lodash-es';

export default class ApiClient {
	constructor(private token: string) {}

	async call(path: string, options?: RequestInit): Promise<object> {
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

		return await response.json();
	}
}
