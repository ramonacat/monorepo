<script lang="ts">
	import Icon from '@iconify/svelte';
	import { MessageType } from '$lib/components/forms/MessageType';

	export let type: MessageType;
	export let visible: boolean = false;

	let typeClassName: string = typeToClassName(type);
	$: typeClassName = typeToClassName(type);

	function typeToClassName(type: MessageType): string {
		return type === MessageType.Failure ? '-failure' : '-success';
	}

	function hide(): void {
		visible = false;
	}
</script>

{#if visible}
	<div class="message {typeClassName}">
		<p>
			<slot></slot>
		</p>
		<button on:click={hide}><Icon inline icon="mdi:close" /></button>
	</div>
{/if}

<style>
	.message {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: space-between;
		flex-direction: column-reverse;
	}

	.message p,
	.message button {
		margin: var(--spacing-m);
		padding: 0;
	}

	.message button {
		border: 0;
		background-color: transparent;
		cursor: pointer;
		font-size: 2rem;
		margin-left: auto;
		margin-right: 0;
	}

	.message.-failure {
		color: var(--color-danger);
		background-color: var(--color-background-danger);
	}

	.message.-success {
		color: var(--color-success);
		background-color: var(--color-background-success);
	}
</style>
