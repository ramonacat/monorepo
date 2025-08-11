#!/usr/bin/env bash
set -euo pipefail

read-closure() {
	local -r path=$1
	local closure=''

	mapfile -t builds_hosts < <(echo "$BUILDERS" | jq --raw-output --compact-output '.[]')

	for builds_host in "${builds_hosts[@]}"; do
		echo "trying $builds_host..." >&2

		if closure=$(curl --fail --max-time 5 "https://$builds_host.ibis-draconis.ts.net/$path" | tr -d '\n'); then
			break
		else
			closure=''
		fi
	done

	if [[ "$closure" == '' ]]; then
		exit 1
	fi

	nix-store --realise "$closure" >/dev/null
	echo "$closure"
}
