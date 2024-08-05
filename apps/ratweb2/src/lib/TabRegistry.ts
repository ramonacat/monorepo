export interface TabRegistry {
	register(name: string, hide: () => void, show: () => void): void;
}
