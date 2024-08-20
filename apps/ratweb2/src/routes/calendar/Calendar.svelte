<script lang="ts">
	import type { CalendarEvent } from '$lib/CalendarEvent';
	import { generateCalendar } from '$lib/calendar';

	export let year;
	export let month;
	export let calendarEvents: { [key: number]: CalendarEvent[] };

	const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
	let calendar = generateCalendar(year, month);
	$: calendar = generateCalendar(year, month);
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
					<td>
						{day.dayNumber ?? ''}
						{#if day.dayNumber && calendarEvents[day.dayNumber]}
							<ul>
								{#each calendarEvents[day.dayNumber] as event}
									<li>
										{#if event.time}
											<span class="time">{event.time}</span>
										{/if}
										{event.name}
									</li>
								{/each}
							</ul>
						{/if}
					</td>
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

	@media (max-width: 500px) {
		th {
			writing-mode: vertical-rl;
		}

		th,
		td {
			font-size: 1.5rem;
			height: auto;
		}
	}
</style>
