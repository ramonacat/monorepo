<script lang="ts">
	import TagPill from '$lib/components/TagPill.svelte';
	import type { TaskSummaryView } from '$lib/TaskSummaryView';
	import Icon from '@iconify/svelte';
	export let showDetails = false;
	export let task: TaskSummaryView;
</script>

<button class="title" on:click={() => (showDetails = !showDetails)}>
	{task.title}
	{#if task.deadline}
		<span class="deadline">
			({task.deadline.toLocaleString({ timeStyle: 'medium', dateStyle: 'medium' })})
		</span>
	{/if}
</button>
{#if showDetails}
	<div class="tags">
		{#each task.tags as tag}
			<TagPill>{tag}</TagPill>
		{/each}
	</div>
	<div class="actions">
		<div class="button-group -left">
			<button title="edit"><Icon inline icon="mdi:edit" /></button>
			<form method="POST" action="/?/start_task">
				<input type="hidden" name="task-id" value={task.id} />
				<button title="start"><Icon inline icon="mdi:stopwatch-start" /></button>
			</form>
			<button title="done"><Icon inline icon="mdi:done" /></button>
		</div>
		<div class="button-group -right">
			<button class="-danger" title="remove"><Icon inline icon="mdi:remove" /></button>
		</div>
	</div>
{/if}

<style>
	button {
		cursor: pointer;
	}
	button.title {
		border: 0;
		margin: 0;
		background-color: transparent;
		display: inline;
	}

	.actions {
		width: 100%;
		margin-top: var(--spacing-m);
		margin-bottom: var(--spacing-l);

		display: flex;
		justify-content: space-between;
	}

	.actions button:not(:last-child) {
		border-right: 0;
	}

	.actions button {
		font-size: 2rem;
		width: auto;
		height: auto;
	}

	.tags {
		margin-top: var(--spacing-xs);
	}

	.button-group {
		display: flex;
	}
</style>
