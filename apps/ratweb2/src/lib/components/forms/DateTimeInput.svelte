<script lang="ts">
	export let dateName:string = 'date';
	export let timeName:string = 'time';
</script>

<div class="datetime">
	<input type="date" name={dateName} class="date" />
	<input type="time" name={timeName} class="time" />
</div>

<style>
	.datetime {display: flex;}
	.time {border-left: 0;}
</style>