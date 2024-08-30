<script lang="ts">
	import Tabs from '$lib/components/Tabs.svelte';
	import CreateBacklogItemForm from './CreateBacklogItemForm.svelte';
	import TaskList from '$lib/components/TaskList.svelte';
	import SectionHeading from '$lib/components/SectionHeading.svelte';
	import Tab from '$lib/components/Tab.svelte';
	import type { ActionData, PageData } from './$types';
	import CreateIdeaForm from './CreateIdeaForm.svelte';
	import CreateEventForm from './CreateEventForm.svelte';
	import { Filter, TaskSummary } from '$lib/api/task';
	import { ServerUserView } from '$lib/api/user';
	import Icon from '@iconify/svelte';
	import { chunk } from 'lodash-es';

	export let form: ActionData;
	export let data: PageData;

	const upcomingTasks = data.upcomingTasks.map(TaskSummary.fromPojo);
	const watchedTasks = data.watchedTasks.map(TaskSummary.fromPojo);
	const allUsers = data.allUsers.map(ServerUserView.fromPojo);
	const ideas = data.ideas.map(TaskSummary.fromPojo);
	const customFilteredTasksRaw = data.customFilteredTasks;
	const customFilteredTasks: { [key: string]: TaskSummary[] } = {};
	for (const filterId in customFilteredTasksRaw) {
		customFilteredTasks[filterId] = customFilteredTasksRaw[filterId].map(TaskSummary.fromPojo);
	}

	const filters = chunk(data.filters.map(Filter.fromPojo), 3);
</script>

<svelte:head>
	<title>Ramona's Service</title>
</svelte:head>

<div class="container">
	<section>
		<Tabs description="create" currentTabIndex={form?.currentTab ?? 0}>
			<Tab name="task">
				<CreateBacklogItemForm {form} {allUsers} />
			</Tab>
			<Tab name="event">
				<CreateEventForm {form} {allUsers} />
			</Tab>
			<Tab name="idea">
				<CreateIdeaForm {form} />
			</Tab>
		</Tabs>
	</section>
	<section>
		<SectionHeading>upcoming</SectionHeading>
		<TaskList tasks={upcomingTasks}></TaskList>
	</section>
	<section>
		<SectionHeading>todos from watched tags</SectionHeading>
		<TaskList tasks={watchedTasks}></TaskList>
	</section>
</div>
<div class="container">
	<section>
		<SectionHeading>ideas</SectionHeading>
		<TaskList tasks={ideas}></TaskList>
	</section>
	<section>
		<SectionHeading>add custom view</SectionHeading>
		<a href="/custom-view-create"><Icon icon="mdi:plus" /> create a custom view</a>
	</section>
</div>
{#each filters as chunk}
	<div class="container">
		{#each chunk as filter}
			<section>
				<SectionHeading>{filter.name}</SectionHeading>
				<TaskList tasks={customFilteredTasks[filter.id]}></TaskList>
			</section>
		{/each}
	</div>
{/each}

<style>
	.container {
		display: grid;
		grid-template-columns: 1fr 1fr 1fr;
	}

	section {
		margin-bottom: var(--spacing-xl);
	}

	@media (max-width: 500px) {
		.container {
			display: block;
		}
	}
</style>
