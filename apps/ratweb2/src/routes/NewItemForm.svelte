<script>
	import TagsInput from './TagsInput.svelte';
</script>

<form method="POST">
	<div class="row">
		<label for="title">title:</label>
		<input type="text" name="title" />
	</div>
	<div class="row">
		<label for="tags">tags:</label>
		<TagsInput />
	</div>
	<div class="row">
		<label for="deadline">deadline:</label>
		<input type="datetime-local" name="deadline" id="deadline" />
	</div>

	<div class="row submit-row">
		<button type="submit">submit</button>
	</div>
</form>

<style>
	form {margin: 0 auto; width: var(--width-input);}
</style>