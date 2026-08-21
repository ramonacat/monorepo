#!/usr/bin/env bash
set -euo pipefail

declare ATTIC_PID=""

hack-renovate-update() {
	git config user.name "roboramona"
	git config user.email "<>"

	nix build '.#rapp.mitmCache.updateScript' && ./result

	if [[ ! -z "$(git status --porcelain)" ]]; then
		git checkout -b "$CI_COMMIT_SOURCE_BRANCH"
		git commit -am"update deps.json"
		git push origin "$CI_COMMIT_SOURCE_BRANCH"

		exit 1
	fi
}

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

	hack-renovate-update

	nix build '.#everything' --fallback --print-build-logs
	ci validate-built

	if [[ "${CI_COMMIT_SOURCE_BRANCH:-${CI_COMMIT_BRANCH:-main}}" == "main" ]]; then
		echo "on the main branch, publishing changed containers"

		ci publish
	fi

	ci cache push terraform terraform/.terraform
}

main
