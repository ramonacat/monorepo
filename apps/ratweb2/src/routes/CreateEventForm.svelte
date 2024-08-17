<script lang="ts">
	import TagsInput from '$lib/components/forms/TagsInput.svelte';
	import type { ActionData } from '../../.svelte-kit/types/src/routes/$types';
	import Icon from '@iconify/svelte';
	import Message from '$lib/components/forms/Message.svelte';
	import { MessageType } from '$lib/components/forms/MessageType';
	import DateTimeInput from '$lib/components/forms/DateTimeInput.svelte';
	import UserInput from '$lib/components/forms/UserInput.svelte';
	import type { ServerUserView } from '$lib/ServerUserView';

	export let form: ActionData;
	export let allUsers: ServerUserView[];
</script>

<form method="POST" action="?/create_event">
	<Message type={MessageType.Success} visible={form?.success}>
		<Icon inline icon="mdi:check-circle" />
		Event created
	</Message>
	<Message type={MessageType.Failure} visible={form?.failed}>
		<Icon inline icon="mdi:cross-circle" />
		An error has occurred during creation of the event
	</Message>
	<div class="row">
		<label for="title">title:</label>
		<input type="text" name="title" />
	</div>

	<div class="row">
		<label for="start-time">start:</label>
		<DateTimeInput dateName="start-date" timeName="start-time" />
	</div>

	<div class="row">
		<label for="end">end:</label>
		<DateTimeInput dateName="end-date" timeName="end-time" />
	</div>

	<div class="row">
		<label for="attendees">attendees:</label>
		<UserInput {allUsers} multiple required name="attendees" />
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
