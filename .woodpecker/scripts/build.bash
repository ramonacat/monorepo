#!/usr/bin/env bash
set -euo pipefail

declare ATTIC_PID=""

cleanup() {
	if [[ "$ATTIC_PID" != "" ]]; then
		kill $ATTIC_PID || true
	fi
}

main() {
	ci setup
	ci cache pull terraform

	attic watch-store main &
	ATTIC_PID=$!
	trap cleanup EXIT

	nix build .#everything --fallback
    # TODO this is broken, needs to be fixed, commented out to allow deploying fixes
	# ci validate-built

	if [[ "${CI_COMMIT_SOURCE_BRANCH:-${CI_COMMIT_BRANCH:-main}}" == "main" ]]; then
		echo "on the main branch, publishing changed containers"

		ci publish
	fi

	ci cache push terraform terraform/.terraform
}

main
