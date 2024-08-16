export interface Tab {
	name: string;
	hide: () => void;
	show: () => void;
	index: number;
}
