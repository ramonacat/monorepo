import type { SvelteComponent_1 } from 'svelte';

export interface Tab {
	name: string,
	hide: () => void,
	show: () => void
}