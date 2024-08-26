<script lang="ts">
	import { MessageType } from '$lib/components/forms/MessageType';
	import Message from '$lib/components/forms/Message.svelte';
	import Icon from '@iconify/svelte';
	import type { PageData } from './$types';
	import TagsInput from '$lib/components/forms/TagsInput.svelte';
	import DateTimeInput from '$lib/components/forms/DateTimeInput.svelte';
	import type { ActionData } from '../../../.svelte-kit/types/src/routes/$types';
	import { TaskSummary } from '$lib/TaskSummary';
	import UserInput from '$lib/components/forms/UserInput.svelte';
	import { ServerUserView } from '$lib/ServerUserView';

	export let form: ActionData;
	export let data: PageData;

	const task = TaskSummary.fromPojo(data.task);
	const allUsers = data.allUsers.map(ServerUserView.fromPojo);
</script>

<div class="root">
	<form method="POST">
		<Message type={MessageType.Success} visible={form?.success}>
			<Icon inline icon="mdi:check-circle" />
			Task updated
		</Message>
		<Message type={MessageType.Failure} visible={form?.failed}>
			<Icon inline icon="mdi:cross-circle" />
			An error has occurred during the update of the task
		</Message>
		<div class="row">
			<label for="title">title:</label>
			<input type="text" name="title" value={task.getTitle()} />
		</div>
		<div class="row">
			<label for="tags">tags:</label>
			<TagsInput name="tags" selectedTags={task.getTags()} />
		</div>
		<div class="row">
			<label for="deadline">deadline:</label>
			<DateTimeInput dateName="deadline-date" timeName="deadline-time" value={task.getDeadline()} />
		</div>
		<div class="row">
			<label for="assignee">assignee:</label>
			<UserInput name="assignee" {allUsers} value={task.getAssigneeId()} />
		</div>

		<div class="row submit-row">
			<button type="submit">submit</button>
		</div>
	</form>
</div>

<style>
	.root {
		min-height: 100dvh;
		display: grid;
		justify-items: center;
		align-items: center;
	}
</style>
