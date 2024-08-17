<script lang="ts">
	import type { ServerUserView } from '$lib/ServerUserView';

	export let allUsers: ServerUserView[];
	export let name: string;
	export let required: boolean = false;
	export let multiple: boolean = false;
	export let value: string | undefined = undefined;

	let checked = new Set();
	function checkedChange(userID: string, isChecked: boolean) {
		if (isChecked) {
			checked.add(userID);
		} else {
			checked.delete(userID);
		}

		checked = checked;
	}

	console.log(value);
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
			<option value={user.id} selected={value === user.id}>{user.username}</option>
		{/each}
	</select>
{/if}
