<script lang="ts">
	import { DateTime } from 'luxon';

	export let since:DateTime;

	let duration = DateTime.now().diff(since);

	setInterval(() => {
		duration = DateTime.now().diff(since);
	}, 1000);
</script>

{duration.rescale().toFormat('hh:mm:ss')}
