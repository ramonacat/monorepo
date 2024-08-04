<script lang="ts">
	export let tasks: TaskSummaryView[] = [];

	import type { TaskSummaryView } from '$lib/TaskSummaryView';
</script>


<ul>
	{#each tasks as task}
		<li class:past-deadline={task.pastDeadline}>
			{task.name}
			{#if task.deadline}
			<span class="deadline">
				({task.deadline.toLocaleString({timeStyle: "medium", dateStyle: 'medium'})})
			</span>
			{/if}
		</li>
	{/each}
</ul>

<style>
	li {
			list-style-type: square;
	}

	li.past-deadline::marker {
			color: var(--color-danger);
	}
</style>
