<script>
	import { getContext } from 'svelte';
	export let name;

	let visible = true;
	getContext('registry').register(name, () => visible = false, () => visible = true)
</script>

<div class:hide={!visible}>
	<slot></slot>
</div>

<style>
	.hide {
		display: none;
	}
</style>