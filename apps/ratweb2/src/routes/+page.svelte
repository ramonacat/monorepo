<script lang="ts">
	import Tabs from '$lib/components/Tabs.svelte';
	import NewItemForm from './NewItemForm.svelte';
	import TaskList from '$lib/components/TaskList.svelte';
	import SectionHeading from '$lib/components/SectionHeading.svelte';
	import Tab from '$lib/components/Tab.svelte';
	import CurrentTask from './ActiveTask.svelte';
	import type { ActionData } from '../../.svelte-kit/types/src/routes/$types';
	import type { PageData } from './$types';
	import { ServerTaskSummary } from '$lib/ServerTaskSummary';
	import { ServerCurrentTaskView } from '$lib/ServerCurrentTaskView';

	export let form: ActionData;
	export let data: PageData;

	const upcomingTasks = data.upcomingTasks.map(ServerTaskSummary.fromPojo);
	const watchedTasks = data.watchedTasks.map(ServerTaskSummary.fromPojo);
	const currentTask = data.currentTask ? ServerCurrentTaskView.fromPojo(data.currentTask) : null;
</script>

<svelte:head>
	<title>Ramona's Service</title>
</svelte:head>

{#if currentTask}
	<section>
		<SectionHeading>Currently doing</SectionHeading>
		<CurrentTask task={currentTask}></CurrentTask>
	</section>
{/if}

<div class="container">
	<section>
		<Tabs description="create">
			<Tab name="task">
				<NewItemForm {form} />
			</Tab>
			<Tab name="event">event</Tab>
			<Tab name="idea">idea</Tab>
		</Tabs>
	</section>
	<section>
		<SectionHeading>Upcoming</SectionHeading>
		<TaskList tasks={upcomingTasks}></TaskList>
	</section>
	<section>
		<SectionHeading>Todos from watched tags</SectionHeading>
		<TaskList tasks={watchedTasks}></TaskList>
	</section>
</div>

<style>
	.container {
		display: grid;
		grid-template-columns: 1fr 1fr 1fr;
	}

	section {
		margin-bottom: var(--spacing-xl);
	}
</style>
