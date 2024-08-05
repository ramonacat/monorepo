<script lang="ts">
	import { Duration } from 'luxon';

	export let duration: Duration;

	setInterval(() => {
		duration = duration.plus(Duration.fromObject({ second: 1 }));
	}, 1000);
</script>

{duration.rescale().toFormat('hh:mm:ss')}
