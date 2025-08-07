#!/usr/bin/env bash

set -euo pipefail

source "$RAMONA_FLAKE_ROOT"/scripts/lib/populate-ssh-keys.bash

usage() {
	echo "usage: $0 [hostname]" >&2
	echo "this command will create a file called [hostname]-rootfs.tar, which should be used to populate the hostname's rootfs before running nixos-install" >&2
	echo "please note that the bundle contains private ssh host keys" >&2
	exit 1
}

main() {
	local -r hostname=$1

	if ! nix eval --json '.#hosts-nixos' 2>/dev/null | jq --exit-status --arg hostname "$hostname" '. | index($hostname)' >/dev/null; then
		echo "host $hostname is not defined in the flake"
		exit 1
	fi

	local -r root=$(mktemp --directory)

	pushd "$root" >/dev/null || {
		echo "failed to enter $root"
		exit 1
	}

	populate-ssh-keys "$RAMONA_FLAKE_ROOT/secrets/" "$hostname"

	popd >/dev/null || {
		echo "failed to leave $root"
		exit 1
	}

	tar --create --file="./$hostname-rootfs.tar" --directory="$root" .
}

if [[ $# != 1 ]]; then
	usage
fi

main "$1"
