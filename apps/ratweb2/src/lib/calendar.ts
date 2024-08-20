import { DateTime } from 'luxon';
import { range } from 'lodash-es';

export function generateCalendar(year: number, month: number) {
	const firstDay = DateTime.fromObject({ year, month });
	const firstDayOfNextMonth = firstDay.plus({ month: 1 });

	const daysInThisMonth = firstDayOfNextMonth.diff(firstDay).shiftTo('days').days;

	const startingWeekday = firstDay.weekday as number;
	const calendar = [];
	const firstWeek = [];
	const daysInFirstWeek = 7 - (startingWeekday - 1);

	for (let i = 0; i < 7 - daysInFirstWeek; i++) {
		firstWeek.push({});
	}

	for (const day of range(1, daysInFirstWeek + 1)) {
		firstWeek.push({ dayNumber: day });
	}

	calendar.push(firstWeek);

	const fullWeeksCount = Math.floor((daysInThisMonth - daysInFirstWeek) / 7);
	for (let i = 1; i <= fullWeeksCount; i++) {
		const currentWeek = [];
		for (let j = 1; j <= 7; j++) {
			currentWeek.push({ dayNumber: j + (i - 1) * 7 + daysInFirstWeek });
		}
		calendar.push(currentWeek);
	}

	const daysInTheLastWeek = daysInThisMonth - (fullWeeksCount * 7 + daysInFirstWeek);

	const lastWeek = [];
	for (let i = 1; i <= daysInTheLastWeek; i++) {
		lastWeek.push({ dayNumber: daysInFirstWeek + fullWeeksCount * 7 + i });
	}

	for (let i = 0; i < 7 - daysInTheLastWeek; i++) {
		lastWeek.push({});
	}
	calendar.push(lastWeek);

	return calendar;
}
