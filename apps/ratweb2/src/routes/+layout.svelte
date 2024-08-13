<script>
	import '../app.scss';
	import MainMenu from './MainMenu.svelte';
</script>

<div class="app">
	<section>
		<MainMenu />
	</section>
	<main>
		<slot />
	</main>
</div>
