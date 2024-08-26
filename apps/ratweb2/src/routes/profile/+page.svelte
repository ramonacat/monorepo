<script lang="ts">
	import TagsInput from '$lib/components/forms/TagsInput.svelte';
	import type { PageData } from './$types';
	import { TaskUserProfile } from '$lib/TaskUserProfile';

	export let data: PageData;
	let userProfile = TaskUserProfile.fromPojo(data.userProfile);
</script>

<div class="root">
	<form action="/profile?/edit_tasks_profile" method="POST">
		<div class="row">
			<label for="watchedTags">watched tags:</label>
			<TagsInput name="watchedTags" selectedTags={userProfile.watchedTags.map((x) => x.name)} />
		</div>

		<div class="row">
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
