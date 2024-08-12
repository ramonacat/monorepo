<script lang="ts">
	import Icon from '@iconify/svelte';
	import TimeCounter from '$lib/components/TimeCounter.svelte';
	import type { CurrentTaskView } from '$lib/CurrentTaskView';

	export let task: CurrentTaskView;
</script>

<span class="name">{task.title}</span>
<span class="time-spent"><TimeCounter since={task.startTime} isPaused={task.isPaused} /></span>

<div class="buttons">
	{#if !task.isPaused}
		<form method="POST" action="?/pause_task">
			<input type="hidden" name="task-id" value={task.id} />
			<button title="pause"><Icon inline icon="mdi:pause" /></button>
		</form>
	{/if}
	{#if task.isPaused}
		<form method="POST" action="?/start_task">
			<input type="hidden" name="task-id" value={task.id} />
			<button title="pause"><Icon inline icon="mdi:play" /></button>
		</form>
	{/if}
	<form method="POST" action="?/finish_task">
		<input type="hidden" name="task-id" value={task.id} />
		<button title="done"><Icon inline icon="mdi:done" /></button>
	</form>
	<form method="POST" action="?/return_to_backlog">
		<input type="hidden" name="task-id" value={task.id} />
		<button title="return to backlog"><Icon inline icon="mdi:assignment-return" /></button>
	</form>
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
