#!/usr/bin/env bash

set -euo pipefail

main() {
	local -r _input=cat <&0

	nix eval --json '..#hosts.tailscale-tags' 2>/dev/null | jq '. | map_values(join(" ")) | map_values(select(. != ""))'
}

main
