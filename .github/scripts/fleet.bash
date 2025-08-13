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

	local -r dry_run_result=$(hacked-fleetctl gitops --dry-run "${args[@]}" 2>&1)
	local wet_run_result=''

	if [[ "$branch_name" == "main" ]]; then
		wet_run_result=$(hacked-fleetctl gitops "${args[@]}")
	fi

	{
		echo "READABLE_OUTPUT<<EOF"
		echo "# fleet"

		echo "# dry run result"
		echo -e "${dry_run_result//$'\n'/<br/>}"

		if [[ "$wet_run_result" != "" ]]; then
			echo "# wet run result"
			echo -e "${wet_run_result//$'\n'/<br/>}"
		fi

		echo "EOF"
	} >>"$GITHUB_OUTPUT"

	cat "$GITHUB_OUTPUT" >>"$GITHUB_STEP_SUMMARY"
}

if [[ $# -ne 1 ]]; then
	usage
fi

main "$1"
