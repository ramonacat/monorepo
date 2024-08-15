<script lang="ts">
	import { page } from '$app/stores';
	const links = [
		{ path: '/', text: 'Tasks' },
		{ path: '/calendar', text: 'Calendar' }
	];
</script>

<menu>
	{#each links as link}
		<li><a href={link.path} class:active={$page.url.pathname === link.path}>{link.text}</a></li>
	{/each}
</menu>

<style>
	li,
	menu {
		margin: 0;
		padding: 0;
	}

	li {
		list-style: none;
	}

	li a {
		display: block;
		padding: 0 var(--spacing-xl);
		font-size: 2rem;
		text-decoration: none;
	}

	menu {
		display: flex;
		height: var(--height-heading);
		align-items: center;
	}

	.active {
		color: var(--color-link-hover);
	}

	@media (max-width: 500px) {
		menu {
			display: block;
			height: auto;
			margin: 0;
			text-align: center;
		}

		menu li a {
			display: block;
			margin: var(--spacing-xl) auto;
		}
	}
</style>
