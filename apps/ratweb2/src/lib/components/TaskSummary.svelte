<script lang="ts">
	import TagPill from '$lib/components/TagPill.svelte';
	import Icon from '@iconify/svelte';
	import type { TaskSummary } from '$lib/api/task';
	export let showDetails = false;
	export let task: TaskSummary;
</script>

<button class="title" on:click={() => (showDetails = !showDetails)}>
	{task.title}
	{#if task.assigneeName}
		- {task.assigneeName}
	{/if}
	{#if task.deadline}
		<span class="deadline">
			({task.deadline.toDateTime().toLocaleString({ timeStyle: 'medium', dateStyle: 'medium' })})
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
			<a class="button" href="/todo-edit?task-id={task.id}" title="edit">
				<Icon inline icon="mdi:edit" />
			</a>
			{#if task.getStatus() !== 'IDEA'}
				<form method="POST" action="/?/start_task">
					<input type="hidden" name="task-id" value={task.id} />
					<button title="start"><Icon inline icon="mdi:stopwatch-start" /></button>
				</form>
				<form method="POST" action="/?/finish_task">
					<input type="hidden" name="task-id" value={task.id} />
					<button title="done"><Icon inline icon="mdi:done" /></button>
				</form>
				<form method="POST" action="/?/return_to_idea">
					<input type="hidden" name="task-id" value={task.id} />
					<button title="return to idea"><Icon inline icon="mdi:lightbulb-on-outline" /></button>
				</form>
			{/if}
		</div>
		<div class="button-group -right">
			<button class="-danger" title="remove"><Icon inline icon="mdi:remove" /></button>
		</div>
	</div>
{/if}

<style>
	button,
	.button {
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

	.actions button,
	.actions .button {
		font-size: 2rem;
		line-height: 1.25;
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
