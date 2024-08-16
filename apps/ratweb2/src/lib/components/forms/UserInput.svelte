<script lang="ts">
	import type { ServerUserView } from '$lib/ServerUserView';

	export let allUsers: ServerUserView[];
	export let name: string;
	export let required: boolean = false;
	export let multiple: boolean = false;
</script>

<select {name} {multiple}>
	{#if !required}
		<option value="">none</option>
	{/if}
	{#each allUsers as user}
		<option value={user.id}>{user.username}</option>
	{/each}
</select>
