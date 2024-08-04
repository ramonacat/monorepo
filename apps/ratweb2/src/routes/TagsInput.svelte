<script lang="ts">
	import Icon from '@iconify/svelte';
	import TagPill from './TagPill.svelte';
	export let selectedTags: string[] = [];
	let inputtedTag: string = '';

	function addTag(ev: MouseEvent) {
		ev.preventDefault();

		selectedTags = [...selectedTags, inputtedTag];
		inputtedTag = '';
	}

	function removeTag(tag: string) {
		const tagIndex = selectedTags.indexOf(tag);
		selectedTags.splice(tagIndex, 1);
		selectedTags = selectedTags;
	}

	let selectedTagsJson = '[]';

	$: selectedTagsJson = JSON.stringify(selectedTags);
</script>

<div class="tags-input">
	<input type="hidden" name="selected-tags" value={selectedTagsJson} />
	<input type="text" bind:value={inputtedTag} />
	<button on:click={addTag} class="add-tag">add</button>
</div>

<div class="tags">
	{#each selectedTags as tag}
		<TagPill>
			{tag}
			<button
				slot="addon-right"
				class="remove-tag"
				on:click={(ev) => {
					ev.preventDefault();
					removeTag(tag);
				}}
			>
				<Icon icon="mdi:remove" inline /></button
			>
		</TagPill>
	{/each}
</div>

<style>
	.tags-input {
		display: flex;
		align-items: center;
	}

	.tags-input input {
		width: calc(var(--width-input) - 2 * var(--height-input));
	}

	button.add-tag {
		border-left: none;
		width: calc(2 * var(--height-input));
		display: flex;
		justify-content: center;
		justify-items: baseline;
		margin: 0;
		padding: 0;
	}

	button.remove-tag {
		padding: 0;
		border: 0 none;
		background: transparent;
	}
</style>
