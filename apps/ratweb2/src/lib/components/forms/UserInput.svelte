<script lang="ts">
	import type { ServerUserView } from '$lib/ServerUserView';

	export let allUsers: ServerUserView[];
	export let name: string;
	export let required: boolean = false;
	export let multiple: boolean = false;

	let checked = new Set();
	function checkedChange(userID: string, isChecked: boolean) {
		console.log(userID, isChecked);
		if (isChecked) {
			checked.add(userID);
		} else {
			checked.delete(userID);
		}

		checked = checked;
	}
</script>

{#if multiple}
	<input type="hidden" {name} value={JSON.stringify(Array.from(checked.values()))} />
	{#each allUsers as user}
		<label
			><input type="checkbox" on:change={(e) => checkedChange(user.id, e.currentTarget.checked)} />
			{user.username}</label
		>
	{/each}
{/if}

{#if !multiple}
	<select {name}>
		{#if !required}
			<option value="">none</option>
		{/if}
		{#each allUsers as user}
			<option value={user.id}>{user.username}</option>
		{/each}
	</select>
{/if}
