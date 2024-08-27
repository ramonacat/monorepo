import { it, expect, vi } from 'vitest';
import { ensureAuthenticated } from '$lib/ensureAuthenticated';
import type { Cookies } from '@sveltejs/kit';

it('redirects if the cookie is missing', async () => {
	let noopCookies = new (class implements Cookies {
		delete(name: string, opts: import('cookie').CookieSerializeOptions & { path: string }): void {}

		get(name: string, opts?: import('cookie').CookieParseOptions): string | undefined {
			return undefined;
		}

		getAll(opts?: import('cookie').CookieParseOptions): Array<{ name: string; value: string }> {
			return [];
		}

		serialize(
			name: string,
			value: string,
			opts: import('cookie').CookieSerializeOptions & { path: string }
		): string {
			return '';
		}

		set(
			name: string,
			value: string,
			opts: import('cookie').CookieSerializeOptions & { path: string }
		): void {}
	})();

	vi.useFakeTimers();
	const resolveSpy = vi.fn();
	const rejectSpy = vi.fn();

	ensureAuthenticated(noopCookies).then(resolveSpy).catch(rejectSpy);

	await vi.runAllTimersAsync();

	expect(resolveSpy).not.toHaveBeenCalled();
	expect(rejectSpy).toHaveBeenCalledOnce();
});
