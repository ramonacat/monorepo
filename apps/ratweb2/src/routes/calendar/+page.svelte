<script lang="ts">
	import Calendar from './Calendar.svelte';
	import { DateTime } from 'luxon';
	import Icon from '@iconify/svelte';
	import type { PageData } from './$types';
	import { page } from '$app/stores';
	import { type CalendarEvent, EventView } from '$lib/api/calendar';

	export let data: PageData;
	let now = DateTime.now();
	let currentYear = $page.url.searchParams.get('year') ?? now.year;
	$: currentYear = $page.url.searchParams.get('year') ?? now.year;
	let currentMonth = $page.url.searchParams.get('month') ?? now.month;
	$: currentMonth = $page.url.searchParams.get('month') ?? now.month;

	let displayedDate = now.set({ year: currentYear as number, month: currentMonth as number });
	$: displayedDate = now.set({ year: currentYear as number, month: currentMonth as number });

	let nextMonth, nextMonthHref, previousMonth, previousMonthHref;
	$: nextMonth = displayedDate.plus({ month: 1 });
	$: nextMonthHref = '/calendar?year=' + nextMonth.year + '&month=' + nextMonth.month;

	$: previousMonth = displayedDate.minus({ month: 1 });
	$: previousMonthHref = '/calendar?year=' + previousMonth.year + '&month=' + previousMonth.month;

	let calendarEventsRaw = data.events.map((x) => EventView.fromPojo(x));
	let calendarEvents: { [key: number]: CalendarEvent[] } = {};

	for (const calendarEvent of calendarEventsRaw) {
		const day = calendarEvent.start.toDateTime().day;
		if (!Object.prototype.hasOwnProperty.call(calendarEvents, day)) {
			calendarEvents[day] = [];
		}

		calendarEvents[day].push({
			name: calendarEvent.title,
			time: calendarEvent.start.toDateTime().toFormat('HH:mm')
		});
	}
</script>

<div>
	<a data-sveltekit-reload href={previousMonthHref}><Icon inline icon="mdi:navigate-before" /></a>
	<span>{currentYear}-{currentMonth}</span>
	<a data-sveltekit-reload href={nextMonthHref}><Icon inline icon="mdi:navigate-next" /></a>
</div>
<Calendar year={currentYear} month={currentMonth} {calendarEvents} />

<style>
	div {
		display: flex;
		justify-content: space-between;
		margin-bottom: var(--spacing-m);
	}

	div,
	a {
		font-size: 3rem;
	}
</style>
