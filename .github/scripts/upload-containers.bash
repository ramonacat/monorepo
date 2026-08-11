#!/usr/bin/env bash
set -euo pipefail

main() {
	local image_name
	local tag
	local versions_payload
	local store_path
	local versions_response
	local is_updated
	local version
	local -r now=$(date +%s)

	for image_path in ./result/containers/*; do
		image_name=$(basename "$image_path")
		tag="ghcr.io/ramonacat/$image_name:$now"

		store_path=$(realpath "$image_path")
		versions_payload=$(jq --null-input --arg item "${image_path:2}" --arg store_path "$store_path" '{"versioned_item": $item, "store_path": $store_path}')

		versions_response=$(curl --fail --request POST \
			--header 'Content-Type: application/json' \
			--data "$versions_payload" \
			"https://ras.infrastructure.ramona.fun/versions")

		is_updated=$(echo -n "$versions_response" | jq '.updated')
		version=$(echo -n "$versions_response" | jq '.version')

		if [[ "$is_updated" == "true" ]]; then
			echo "store path changed, uploading new version ($version)"

			docker load --input "$image_path"
			docker tag "$image_name:latest" "$tag"
			docker push "$tag"
		fi

		echo "pushed: $tag"
	done
}

main
