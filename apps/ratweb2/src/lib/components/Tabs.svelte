<script lang="ts">
	import type { Tab } from '$lib/Tab';
	import { setContext } from 'svelte';

	export let description: string = '';

	let tabs: Tab[] = [];
	let currentTab: Tab | undefined;

	function switchTab(tab: Tab) {
		if (currentTab) {
			currentTab.hide();
		}
		tab.show();

		currentTab = tab;
	}
	let tabCount = 0;
	setContext('registry', {
		register: (name: string, hide: () => void, show: () => void) => {
			tabCount++;
			tabs.push({ name, hide, show });
			tabs = tabs;

			if (tabCount > 1) {
				hide();
			} else {
				show();
				currentTab = tabs[0];
			}
		}
	});
</script>

<div class="heading">
	{#if description !== ''}
		<p class="description">{description}</p>
	{/if}
	{#each tabs as tab}
		<button on:click={() => switchTab(tab)} class:active={currentTab?.name === tab.name}>
			{tab.name}
		</button>
	{/each}
</div>
<div class="contents">
	<slot />
</div>

<style>
	div,
	p {
		margin: 0;
		padding: 0;
	}

	.heading {
		display: flex;
		height: var(--height-heading);
		align-items: center;
		background-color: var(--color-background-secondary);
	}

	.heading p {
		margin: 0;
		padding: var(--spacing-m);
		text-align: right;
		flex: 1;
	}

	button {
		background-color: var(--color-background-secondary);
		border: var(--width-border) solid var(--color-accent-3);
		margin: 0;
		padding: 0 var(--spacing-l);
		height: 100%;
	}

	button:not(:last-child) {
		border-right: none;
	}

	button.active {
		background-color: var(--color-accent-3);
		color: var(--color-text-inverted);
	}
</style>
