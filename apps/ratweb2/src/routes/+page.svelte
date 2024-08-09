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

	let tasks2: TaskSummaryView[] = [
		{
			title: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: 100 }))
				.setLocale('en-GB'),
			pastDeadline: false,
			tags: ['network', 'stability']
		},
		{
			title: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: 50 }))
				.setLocale('en-GB'),
			pastDeadline: false,
			tags: ['hardware', 'design']
		},
		{
			title: 'test 123',
			pastDeadline: false,
			tags: ['important', 'drawing']
		},
		{
			title: 'test 123',
			pastDeadline: false,
			tags: ['alpha', 'beta', 'gamma', 'delta']
		}
	];
	let currentTask: ActiveTaskView = {
		workStartedAt: DateTime.now(),
		name: 'This is a task'
	};

	export let form: ActionData;
	export let data: PageData;

	const upcomingTasks = data.upcomingTasks.map(
		(x: { title: string; tags: string[]; deadline: string; pastDeadline: boolean }) => {
			return {
				title: x.title,
				tags: x.tags,
				deadline: DateTime.fromISO(x.deadline),
				pastDeadline: x.pastDeadline
			} satisfies TaskSummaryView;
		}
	);
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
		<SectionHeading>To do this week</SectionHeading>
		<TaskList tasks={upcomingTasks}></TaskList>
	</section>
	<section>
		<SectionHeading>Todos from watched tags</SectionHeading>
		<TaskList tasks={tasks2}></TaskList>
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
