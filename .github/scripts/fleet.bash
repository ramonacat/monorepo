#!/usr/bin/env bash

set -euo pipefail

usage() {
	echo "usage: $0 <branch-name>" >&2
	exit 1
}

hacked-fleetctl() {
	# This is a hack because fleetctl tries to create a $HOME/.goquery/history file, and $HOME for this unit is /.
	# We cannot just override the environemnt variable, as the path is retreived from the OS via syscalls that
	# interact with the nss directly.
	proot --bind="$(mktemp --directory):/.goquery/" fleetctl "${@}"
}

main() {
	local -r branch_name=$1
	local -a args=()

	args+=("-f" "./fleet/default.yml")

	hacked-fleetctl config set --address "$FLEET_URL" --token "$FLEET_API_TOKEN"
	hacked-fleetctl gitops --dry-run "${args[@]}"

	if [[ "$branch_name" == "main" ]]; then
		hacked-fleetctl gitops "${args[@]}"
	fi
}

if [[ $# -ne 1 ]]; then
	usage
fi

main "$1"
