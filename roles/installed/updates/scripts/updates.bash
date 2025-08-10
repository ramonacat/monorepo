#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../../../scripts/lib/updates.bash disable=SC1091
source "$UPDATES_LIB"

main() {
	if [[ -f "/var/.stop_updates" ]]; then
		echo "Updates are stopped. Remove /var/.stop_updates to reenable"
		exit
	fi

	local -r current_closure=$(readlink -f /nix/var/nix/profiles/system)
	local -r hostname=$(tr -d '[:space:]' </etc/hostname)
	local closure
	if ! closure=$(read-closure "builds/$hostname-closure"); then
		echo "Failed to receive the new closure" >&2
		exit 1
	fi

	if [[ "$closure" == "$current_closure" ]]; then
		echo "System already running the latest closure, not rebuilding"
		exit
	fi

	"$closure"/bin/switch-to-configuration switch
	bin/nix-env --profile /nix/var/nix/profiles/system --set "$closure"
}

main
