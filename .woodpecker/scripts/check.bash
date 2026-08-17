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

	ci check

	ci cache push terraform terraform/.terraform
}

main
