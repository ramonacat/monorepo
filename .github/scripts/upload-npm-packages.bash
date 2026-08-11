#!/usr/bin/env bash
set -euo pipefail

main() {
	echo "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}" >~/.npmrc

	for package_path in ./result/npm-packages/*; do
		pushd "$package_path"

		npm publish

		popd
	done
}

main
