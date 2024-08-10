<script lang="ts">
	import type { ActiveTaskView } from '$lib/ActiveTaskView';
	import Icon from '@iconify/svelte';
	import TimeCounter from '$lib/components/TimeCounter.svelte';
	import type { TaskSummaryView } from '$lib/TaskSummaryView';
	import { DateTime } from 'luxon';

	export let task: TaskSummaryView;

	const since = DateTime.fromSeconds(task.timeRecords[task.timeRecords.length-1].started.timestamp);
</script>

<span class="name">{task.title}</span>
<span class="time-spent"><TimeCounter since={since} /></span>

<div class="buttons">
	<button title="pause"><Icon inline icon="mdi:pause" /></button>
	<button title="done"><Icon inline icon="mdi:done" /></button>
	<button title="return to todos"><Icon inline icon="mdi:assignment-return" /></button>
</div>

<style>
	.name,
	.time-spent {
		display: block;
		font-size: 10rem;
		text-align: center;
	}

	button {
		width: auto;
		height: auto;
		font-size: 5rem;
		margin: 0 var(--spacing-xl);
		cursor: pointer;
	}

	.buttons {
		margin-bottom: var(--spacing-xl);
		display: flex;
		justify-content: center;
	}
</style>
