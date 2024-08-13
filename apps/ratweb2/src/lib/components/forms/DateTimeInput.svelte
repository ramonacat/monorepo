<script lang="ts">
	import type { DateTime } from 'luxon';

	export let dateName: string = 'date';
	export let timeName: string = 'time';

	export let value: DateTime | undefined = undefined;
</script>

<div class="datetime">
	<input type="date" name={dateName} class="date" value={value?.toISODate()} />
	<input type="time" name={timeName} class="time" value={value?.toFormat('HH:mm')} />
</div>

<style>
	.datetime {
		display: flex;
	}
	.time {
		border-left: 0;
	}
</style>
