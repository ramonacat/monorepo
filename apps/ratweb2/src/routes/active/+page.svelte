<script lang="ts">

import ActiveTask from '../ActiveTask.svelte';
import type { PageData } from './$types';
import { ServerCurrentTaskView } from '$lib/ServerCurrentTaskView';

export let data:PageData;
const activeTask = data.currentTask ? ServerCurrentTaskView.fromPojo(data.currentTask) : undefined;
</script>
{#if activeTask}
<ActiveTask big task="{activeTask}"></ActiveTask>
{/if}