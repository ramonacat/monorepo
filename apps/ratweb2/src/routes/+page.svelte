<script lang="ts">
	import Tabs from './Tabs.svelte';
	import NewItemForm from './NewItemForm.svelte';
	import TaskList from './TaskList.svelte';
	import type { TaskSummaryView } from '$lib/TaskSummaryView';
	import { DateTime, Duration } from 'luxon';
	import SectionHeading from './SectionHeading.svelte';
	import Tab from './Tab.svelte';

	let tasks: TaskSummaryView[] = [
		{
			name: 'test 123',
			deadline: DateTime.now().minus(Duration.fromObject({ days: -10 })).setLocale('en-GB'),
			pastDeadline: true
		},
		{
			name: 'test 123',
			deadline: DateTime.now().minus(Duration.fromObject({ days: 0 })).setLocale('en-GB'),
			pastDeadline: true
		},
		{
			name: 'test 123',
			pastDeadline: false
		},
		{
			name: 'test 123',
			deadline: DateTime.now().minus(Duration.fromObject({ days: 11 })).setLocale('en-GB'),
			pastDeadline: false
		}
	];

	let tasks2: TaskSummaryView[] = [
		{
			name: 'test 123',
			deadline: DateTime.now().minus(Duration.fromObject({ days: 100 })).setLocale('en-GB'),
			pastDeadline: false
		},
		{
			name: 'test 123',
			deadline: DateTime.now().minus(Duration.fromObject({ days: 50 })).setLocale('en-GB'),
			pastDeadline: false
		},
		{
			name: 'test 123',
			pastDeadline: false
		},
		{
			name: 'test 123',
			pastDeadline: false
		}
	];
</script>

<svelte:head>
	<title>Ramona's Service</title>
</svelte:head>

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
		<TaskList tasks={tasks}></TaskList>
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
</style>