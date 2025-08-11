#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../../../../../scripts/lib/updates.bash disable=SC1091
source "$UPDATES_LIB"

main() {
	if [[ -f "$HOME/.stop_updates" ]]; then
		echo "Updates are stopped. Remove $HOME/.stop_updates to reenable"
		exit
	fi

	local -r current_closure=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager")
	local closure

	if ! closure=$(read-closure "builds/$USER-wsl-home"); then
		echo "Failed to receive the new closure" >&2
		exit 1
	fi

	if [[ "$closure" == "$current_closure" ]]; then
		echo "System already running the latest closure, not rebuilding"
		exit
	fi

	nix-store --realise "$closure"
	"$closure/bin/home-manager-generation"
	nix-env --profile "$HOME/.local/state/nix/profiles/home-manager" --set "$closure"
}

main
