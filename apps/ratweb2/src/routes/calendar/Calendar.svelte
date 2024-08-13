<script lang="ts">
	import { DateTime } from 'luxon';
	import { range } from 'lodash-es';

	export let year;
	export let month;

	let weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
	let firstDay = DateTime.fromObject({ year, month });
	let firstDayOfNextMonth = firstDay.plus({ month: 1 });

	let daysInThisMonth = firstDayOfNextMonth.diff(firstDay).shiftTo('days').days;

	let startingWeekday = firstDay.weekday as number;
	let calendar = [];
	let firstWeek = [];
	const daysInFirstWeek = 7 - (startingWeekday - 1);

	for (let i = 0; i < 7 - daysInFirstWeek; i++) {
		firstWeek.push({});
	}

	for (let day of range(1, daysInFirstWeek + 1)) {
		firstWeek.push({ dayNumber: day });
	}

	calendar.push(firstWeek);

	const fullWeeksCount = Math.floor((daysInThisMonth - daysInFirstWeek) / 7);
	for (let i = 1; i <= fullWeeksCount; i++) {
		let currentWeek = [];
		for (let j = 1; j <= 7; j++) {
			currentWeek.push({ dayNumber: j + (i - 1) * 7 + daysInFirstWeek });
		}
		calendar.push(currentWeek);
	}

	const daysInTheLastWeek = daysInThisMonth - (fullWeeksCount * 7 + daysInFirstWeek);

	let lastWeek = [];
	for (let i = 1; i <= daysInTheLastWeek; i++) {
		lastWeek.push({ dayNumber: daysInFirstWeek + fullWeeksCount * 7 + i });
	}

	for (let i = 0; i < 7 - daysInTheLastWeek; i++) {
		lastWeek.push({});
	}
	calendar.push(lastWeek);
</script>

<table>
	<thead>
		<tr>
			{#each weekdays as weekday}
				<th>{weekday}</th>
			{/each}
		</tr>
	</thead>
	<tbody>
		{#each calendar as row}
			<tr>
				{#each row as day}
					<td>{day.dayNumber ?? ''}</td>
				{/each}
			</tr>
		{/each}
	</tbody>
</table>

<style>
	table {
		border-collapse: collapse;
		width: 100%;
		table-layout: fixed;
	}

	td,
	th {
		border: var(--width-border) solid var(--color-accent-1-400);
		padding: var(--spacing-xl) var(--spacing-m);

		font-size: 2rem;
	}
</style>
