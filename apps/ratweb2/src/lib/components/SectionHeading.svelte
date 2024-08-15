<h1><slot></slot></h1>

<style>
	h1 {
		background-color: var(--color-background-secondary);
		height: var(--height-heading);
		text-align: center;
		vertical-align: middle;
		line-height: var(--height-heading);

		border-right: var(--width-border) solid var(--color-background);
	}

	@media (max-width: 500px) {
		h1 {
			font-size: 1.5rem;
		}
	}
</style>
