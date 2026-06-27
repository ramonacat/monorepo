#!/usr/bin/env bash
set -euo pipefail

main() {
	if [[ -f "$HOME/.stop_updates" ]]; then
		echo "Updates are stopped. Remove $HOME/.stop_updates to reenable"
		exit
	fi

	local -r current_closure=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager")
	local -r closure=$(curl --fail "https://ras.infrastructure.ramona.fun/homes/$USER-wsl/latest_closure")

	local -r closure_update=$(jq --null-input --arg current_closure "$current_closure" '{"current_closure": $current_closure}')
	curl --fail --request POST --header 'Content-Type: application/json' --data "$closure_update" \
		"https://ras.infrastructure.ramona.fun/homes/$USER-wsl/current_closure/$(hostname)"

	if [[ "$closure" == "$current_closure" ]]; then
		echo "System already running the latest closure, not rebuilding"
		exit
	fi

	nix-store --realise "$closure"
	"$closure/bin/home-manager-generation"
	nix-env --profile "$HOME/.local/state/nix/profiles/home-manager" --set "$closure"
}

main
