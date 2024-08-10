<script lang="ts">
	import Tabs from '$lib/components/Tabs.svelte';
	import NewItemForm from './NewItemForm.svelte';
	import TaskList from '$lib/components/TaskList.svelte';
	import type { TaskSummaryView } from '$lib/TaskSummaryView';
	import { DateTime, Duration } from 'luxon';
	import SectionHeading from '$lib/components/SectionHeading.svelte';
	import Tab from '$lib/components/Tab.svelte';
	import CurrentTask from '$lib/components/ActiveTask.svelte';
	import type { ActiveTaskView } from '$lib/ActiveTaskView';
	import type { ActionData } from '../../.svelte-kit/types/src/routes/$types';
	import type { PageData } from './$types';

	let currentTask: ActiveTaskView = {
		workStartedAt: DateTime.now(),
		name: 'This is a task'
	};

	export let form: ActionData;
	export let data: PageData;

	let convertApiTask = (x: {
		id: string;
		title: string;
		tags: string[];
		deadline?: string | null;
		pastDeadline: boolean;
	}) => {
		return {
			id: x.id,
			title: x.title,
			tags: x.tags,
			deadline: x.deadline ? DateTime.fromISO(x.deadline) : null,
			pastDeadline: x.pastDeadline
		} satisfies TaskSummaryView;
	};
	const upcomingTasks: TaskSummaryView[] = data.upcomingTasks.map(convertApiTask);
	const watchedTasks: TaskSummaryView[] = data.watchedTasks.map(convertApiTask);
</script>

<svelte:head>
	<title>Ramona's Service</title>
</svelte:head>

<section>
	<SectionHeading>Currently doing</SectionHeading>
	<CurrentTask task={currentTask}></CurrentTask>
</section>

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
