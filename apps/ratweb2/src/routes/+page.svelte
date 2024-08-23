<script lang="ts">
	import Tabs from '$lib/components/Tabs.svelte';
	import CreateBacklogItemForm from './CreateBacklogItemForm.svelte';
	import TaskList from '$lib/components/TaskList.svelte';
	import SectionHeading from '$lib/components/SectionHeading.svelte';
	import Tab from '$lib/components/Tab.svelte';
	import CurrentTask from './ActiveTask.svelte';
	import type { ActionData } from '../../.svelte-kit/types/src/routes/$types';
	import type { PageData } from './$types';
	import { ServerTaskSummary } from '$lib/ServerTaskSummary';
	import { ServerCurrentTaskView } from '$lib/ServerCurrentTaskView';
	import { ServerUserView } from '$lib/ServerUserView';
	import CreateIdeaForm from './CreateIdeaForm.svelte';
	import CreateEventForm from './CreateEventForm.svelte';

	export let form: ActionData;
	export let data: PageData;

	const upcomingTasks = data.upcomingTasks.map(ServerTaskSummary.fromPojo);
	const watchedTasks = data.watchedTasks.map(ServerTaskSummary.fromPojo);
	const allUsers = data.allUsers.map(ServerUserView.fromPojo);
	const ideas = data.ideas.map(ServerTaskSummary.fromPojo);
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
</div>

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
