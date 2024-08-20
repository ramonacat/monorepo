<script lang="ts">
	import '../app.scss';
	import MainMenu from './MainMenu.svelte';
	import CurrentTask from './ActiveTask.svelte';
	import type { PageData } from '../../.svelte-kit/types/src/routes/$types.js';
	import { ServerCurrentTaskView } from '$lib/ServerCurrentTaskView.js';

	export let data: PageData;
</script>

<div class="app">
	<section>
		<MainMenu />
		{#if data.currentTask}
			<CurrentTask task={ServerCurrentTaskView.fromPojo(data.currentTask)}></CurrentTask>
		{/if}
	</section>
	<main>
		<slot />
	</main>
</div>

<style>
	section {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
</style>
