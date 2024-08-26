<script lang="ts">
	import TaskSummary from '$lib/components/TaskSummary.svelte';
	import { TaskSummary as ServerTaskSummary } from '$lib/api/task';

	export let tasks: ServerTaskSummary[] = [];
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
