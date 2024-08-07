<div class="pill" class:has-addon-right={$$slots['addon-right']}>
	<span class="content"><slot /></span>
	{#if $$slots['addon-right']}
		<div class="addon-right">
			<slot name="addon-right" />
		</div>
	{/if}
</div>

<style>
	.pill {
		display: inline-flex;
		border-radius: var(--radius);
		background-color: var(--color-background-secondary);
		border: var(--width-border) solid var(--color-accent-3-500);
		font-size: var(--font-size-s);
		line-height: var(--height-unit);
		vertical-align: middle;
		align-items: center;
		height: var(--height-unit);
		padding: 0 var(--spacing-s);
		margin: var(--spacing-xs) var(--spacing-xs) 0 0;
	}

	.addon-right {
		border-left: var(--width-border) solid var(--color-accent-3-500);
		margin: 0;
		padding-left: var(--spacing-xs);
		height: var(--height-unit);
		vertical-align: middle;
		line-height: var(--height-unit);
	}

	.has-addon-right .content {
		padding-right: var(--spacing-s);
	}
</style>
