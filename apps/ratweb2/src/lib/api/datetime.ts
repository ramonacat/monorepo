import { DateTime } from 'luxon';

export interface PojoDateTime {
	timestamp: string;
	timezone: string;
}

export class ServerDateTime {
	private timestamp: string;
	private timezone: string;

	public constructor(timestamp: string, timezone: string) {
		this.timestamp = timestamp;
		this.timezone = timezone;
	}

	public toDateTime(): DateTime {
		return DateTime.fromFormat(this.timestamp, 'yyyy-MM-dd HH:mm:ss', { zone: this.timezone });
	}

	public toPojo() {
		return { timestamp: this.timestamp, timezone: this.timezone };
	}

	public static fromPojo(deadline: PojoDateTime) {
		return new ServerDateTime(deadline.timestamp, deadline.timezone);
	}
}
