#!/usr/bin/env bash
set -euo pipefail

main() {
	local -r now=$(date +%s)

	for image_path in ./containers/*; do
		local -r image_name=$(basename "$image_path")
		local -r tag="ghcr.io/ramonacat/$image_name:$now"

		docker load --input "$image_path"
		docker tag "$image_name:latest" "$tag"
		docker push "$tag"
	done
}

main
