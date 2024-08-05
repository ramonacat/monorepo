<script lang="ts">
	import { getContext } from 'svelte';
	import type { TabRegistry } from '$lib/TabRegistry';
	export let name;

	let visible = true;

	(getContext('registry') as TabRegistry).register(
		name,
		() => (visible = false),
		() => (visible = true)
	);
</script>

<div class:hide={!visible}>
	<slot></slot>
</div>

<style>
	.hide {
		display: none;
	}
</style>
