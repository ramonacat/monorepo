<script>
	import Calendar from './Calendar.svelte';
	import { DateTime } from 'luxon';
	import Icon from '@iconify/svelte';

	let now = DateTime.now();
	let currentYear = now.year;
	let currentMonth = now.month;

	$: currentYear = now.year;
	$: currentMonth = now.month;

	function addMonth() {
		console.log(now);
		now = now.plus({ month: 1 });
		console.log(now);
	}

	function subtractMonth() {
		now = now.minus({ month: 1 });
	}
</script>

<div>
	<button on:click={subtractMonth}><Icon inline icon="mdi:navigate-before" /></button>
	<span>{now.toFormat('yyyy-MM')}</span>
	<button on:click={addMonth}><Icon inline icon="mdi:navigate-next" /></button>
</div>
{#key now}
	<Calendar year={currentYear} month={currentMonth} />
{/key}

<style>
	div {
		display: flex;
		justify-content: space-between;
		margin-bottom: var(--spacing-m);
	}

	div,
	button {
		font-size: 3rem;
	}
	button {
		height: auto;
	}
</style>
