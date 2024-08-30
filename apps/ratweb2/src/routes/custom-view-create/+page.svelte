<script lang="ts">
	import TagsInput from '$lib/components/forms/TagsInput.svelte';
	import UserInput from '$lib/components/forms/UserInput.svelte';
	import type { PageData } from './$types';
	import type { ActionData } from './$types';
	import { ServerUserView } from '$lib/api/user.js';

	export let form: ActionData;
	export let data: PageData;
	const allUsers = data.allUsers.map(ServerUserView.fromPojo);
</script>

<form method="POST">
	<div class="row">
		<label for="name">name:</label>
		<input type="text" name="name" />
	</div>

	<div class="row">
		<label for="tags">tags:</label>
		<TagsInput name="tags" />
	</div>

	<div class="row">
		<label for="assignees">assignees:</label>
		<UserInput multiple {allUsers} name="assignees" />
	</div>

	<div class="row">
		<button type="submit">save</button>
	</div>
</form>
