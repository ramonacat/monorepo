#!/usr/bin/env bash
set -euo pipefail

main() {
	local image_name
	local tag
	local -r now=$(date +%s)

	for image_path in ./containers/*; do
		image_name=$(basename "$image_path")
		tag="ghcr.io/ramonacat/$image_name:$now"

		docker load --input "$image_path"
		docker tag "$image_name:latest" "$tag"
		docker push "$tag"

		echo "pushed: $tag"
	done
}

main
