<script lang="ts">
	import type { TaskSummary as Task } from '$lib/TaskSummary';

	export let tasks: Task[] = [];

	import TaskSummary from '$lib/components/TaskSummary.svelte';
</script>

<ul>
	{#each tasks as task}
		<li class:past-deadline={task.pastDeadline()}>
			<TaskSummary {task} />
		</li>
	{/each}
</ul>

<style>
	li {
		list-style-type: square;
		margin: var(--spacing-l) 0;
	}

	li.past-deadline::marker {
		color: var(--color-danger);
	}
</style>
