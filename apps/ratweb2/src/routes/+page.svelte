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

	let tasks: TaskSummaryView[] = [
		{
			name: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: -10 }))
				.setLocale('en-GB'),
			pastDeadline: true,
			tags: ['housework', 'cleaning']
		},
		{
			name: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: 0 }))
				.setLocale('en-GB'),
			pastDeadline: true,
			tags: ['housework', 'garden']
		},
		{
			name: 'test 123',
			pastDeadline: false,
			tags: ['software', 'maintenance']
		},
		{
			name: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: 11 }))
				.setLocale('en-GB'),
			pastDeadline: false,
			tags: ['network', 'performance']
		}
	];

	let tasks2: TaskSummaryView[] = [
		{
			name: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: 100 }))
				.setLocale('en-GB'),
			pastDeadline: false,
			tags: ['network', 'stability']
		},
		{
			name: 'test 123',
			deadline: DateTime.now()
				.minus(Duration.fromObject({ days: 50 }))
				.setLocale('en-GB'),
			pastDeadline: false,
			tags: ['hardware', 'design']
		},
		{
			name: 'test 123',
			pastDeadline: false,
			tags: ['important', 'drawing']
		},
		{
			name: 'test 123',
			pastDeadline: false,
			tags: ['alpha', 'beta', 'gamma', 'delta']
		}
	];
	let currentTask: ActiveTaskView = {
		workStartedAt: DateTime.now(),
		name: 'This is a task'
	};
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
				<NewItemForm />
			</Tab>
			<Tab name="event">event</Tab>
			<Tab name="idea">idea</Tab>
		</Tabs>
	</section>
	<section>
		<SectionHeading>To do this week</SectionHeading>
		<TaskList {tasks}></TaskList>
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
