#!/usr/bin/env bash
set -euo pipefail

main() {
	for package_path in ./npm-packages/*; do
		pushd "$package_path"

		npm publish

		popd
	done
}

main
