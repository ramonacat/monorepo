import { ServerDateTime } from '$lib/Api';
import type { PojoDateTime } from '$lib/ServerTaskSummary';

export class EventView {
	public constructor(
		public readonly id: string,
		public readonly title: string,
		public readonly start: ServerDateTime,
		public readonly end: ServerDateTime,
		public readonly attendeeUsernames: string[]
	) {}

	public toPojo(): PojoEventView {
		return {
			id: this.id,
			title: this.title,
			start: this.start.toPojo(),
			end: this.end.toPojo(),
			attendeeUsernames: this.attendeeUsernames
		};
	}

	public static fromPojo(input: PojoEventView) {
		return new EventView(
			input.id,
			input.title,
			ServerDateTime.fromPojo(input.start),
			ServerDateTime.fromPojo(input.end),
			input.attendeeUsernames
		);
	}
}

export interface PojoEventView {
	id: string;
	title: string;
	start: PojoDateTime;
	end: PojoDateTime;
	attendeeUsernames: string[];
}
