<script lang="ts">
	import TagsInput from '$lib/components/forms/TagsInput.svelte';
	import type { ActionData } from '../../.svelte-kit/types/src/routes/$types';
	import Icon from '@iconify/svelte';
	import Message from '$lib/components/forms/Message.svelte';
	import { MessageType } from '$lib/components/forms/MessageType';
	import DateTimeInput from '$lib/components/forms/DateTimeInput.svelte';
	import type { ServerUserView } from '$lib/ServerUserView';
	import UserInput from '$lib/components/forms/UserInput.svelte';

	export let form: ActionData;
	export let allUsers: ServerUserView[];
</script>

<form method="POST" action="?/create_backlog_item">
	<Message type={MessageType.Success} visible={form?.success}>
		<Icon inline icon="mdi:check-circle" />
		Task created
	</Message>
	<Message type={MessageType.Failure} visible={form?.failed}>
		<Icon inline icon="mdi:cross-circle" />
		An error has occurred during creation of the task
	</Message>
	<div class="row">
		<label for="title">title:</label>
		<input type="text" name="title" />
	</div>
	<div class="row">
		<label for="tags">tags:</label>
		<TagsInput name="tags" />
	</div>
	<div class="row">
		<label for="deadline">deadline:</label>
		<DateTimeInput dateName="deadline-date" timeName="deadline-time" />
	</div>

	<div class="row">
		<label for="assignee">assignee:</label>
		<UserInput {allUsers} name="assignee" />
	</div>

	<div class="row submit-row">
		<button type="submit">submit</button>
	</div>
</form>

<style>
	form {
		margin: 0 auto;
		width: var(--width-input);
		position: relative;
	}
</style>
