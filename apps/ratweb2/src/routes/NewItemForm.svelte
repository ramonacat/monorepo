<script lang="ts">
	import { fade } from 'svelte/transition';
	import TagsInput from '$lib/components/TagsInput.svelte';
	import type { ActionData } from '../../.svelte-kit/types/src/routes/$types';
	import Icon from '@iconify/svelte';

	export let form: ActionData;

	let successMessageVisible = form?.success;
	let failureMessageVisible = form?.failed;

	function hideSuccessMessage() {
		successMessageVisible = false;
	}

	function hideFailureMessage() {
		failureMessageVisible = false;
	}
</script>

<form method="POST" action="?/create_backlog_item">
	{#if successMessageVisible}
		<div class="message -success">
			<p>
				<Icon inline icon="mdi:check-circle" />
				Task created
			</p>
			<button on:click={hideSuccessMessage}><Icon inline icon="mdi:close" /></button>
		</div>
	{/if}
	{#if failureMessageVisible}
		<div class="message -failure">
			<p>
				<Icon inline icon="mdi:cross-circle" />
				An error has occurred during creation of the task
			</p>
			<button on:click={hideFailureMessage}><Icon inline icon="mdi:close" /></button>
		</div>
	{/if}
	<div class="row">
		<label for="title">title:</label>
		<input type="text" name="title" />
	</div>
	<div class="row">
		<label for="tags">tags:</label>
		<TagsInput name="tags" />
	</div>
	<div class="row">
		<label for="deadline">deadline:</label>
		<input type="datetime-local" name="deadline" id="deadline" />
	</div>

	<div class="row submit-row">
		<button type="submit">submit</button>
	</div>
</form>

<style>
	form {
		margin: 0 auto;
		width: var(--width-input);
		position: relative;
	}

	.message {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-direction: column-reverse;
	}

	.message p,
	.message button {
		margin: var(--spacing-m);
		padding: 0;
	}

	.message button {
		border: 0;
		background-color: transparent;
		cursor: pointer;
		font-size: 2rem;
		margin-left: auto;
		margin-right: 0;
	}

	.message.-failure {
		color: var(--color-danger);
		background-color: var(--color-background-danger);
	}

	.message.-success {
		color: var(--color-success);
		background-color: var(--color-background-success);
	}
</style>
