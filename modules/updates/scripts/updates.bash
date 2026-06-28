#!/usr/bin/env bash
set -euo pipefail

main() {
	if [[ -f "/var/.stop_updates" ]]; then
		echo "Updates are stopped. Remove /var/.stop_updates to reenable"
		exit
	fi

	local -r current_closure=$(readlink -f /run/current-system)

	local -r hostname=$(tr -d '[:space:]' </etc/hostname)
	local -r closure_update=$(jq --null-input --arg current_closure "$current_closure" '{"current_closure": $current_closure}')

	curl --fail --request POST --header 'Content-Type: application/json' --data "$closure_update" \
		"https://ras.infrastructure.ramona.fun/hosts/$hostname/current_closure"

	local -r closure=$(curl --fail "https://ras.infrastructure.ramona.fun/hosts/$hostname/latest_closure")

	if [[ "$closure" == "$current_closure" ]]; then
		echo "System already running the latest closure, not rebuilding"
		exit
	fi

	nix-store --realise "$closure"

	"$closure"/bin/switch-to-configuration "$UPDATES_MODE"

	if [[ "$UPDATES_MODE" == "switch" ]]; then
		nix-env --profile /nix/var/nix/profiles/system --set "$closure"
	fi

	[ -n "$UPDATES_POST" ] && $UPDATES_POST
}

main
