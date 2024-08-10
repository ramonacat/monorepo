<script lang="ts">
	import { DateTime, Duration } from 'luxon';

	export let since: DateTime;
	export let isPaused: boolean;

	let duration = DateTime.now().diff(since);

	setInterval(() => {
		if (isPaused) {
			duration = Duration.fromObject({second: 0});
			return;
		}

		duration = DateTime.now().diff(since);
	}, 1000);
</script>

<span class:paused={isPaused}>{duration.rescale().toFormat('hh:mm:ss')}</span>

<style>
	.paused {
		color: var(--color-text-secondary);
	}
</style>
