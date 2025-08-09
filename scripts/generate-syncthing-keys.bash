#!/usr/bin/env bash

set -euo pipefail

usage() {
	echo "usage: $0 [secrets-path] [hostname]" >&2

	exit 1
}

main() {
	local -r secrets_path=$1
	local -r hostname=$2
	local -r config=$(mktemp --directory)

	syncthing generate --home="$config" >/dev/null

	local -r device_id=$(xidel "$config/config.xml" --xpath '/configuration/device/@id')

	pushd "$secrets_path" >/dev/null || {
		echo "failed to enter the secrets diretory"
		exit 1
	}

	agenix -e "$hostname-syncthing-cert.age" >/dev/null <"$config/cert.pem"
	agenix -e "$hostname-syncthing-key.age" >/dev/null <"$config/key.pem"

	popd >/dev/null || {
		echo "failed to leave the secrets directory"
		exit 1
	}

	echo "$device_id"

	rm -r "$config"
}

if [[ $# -ne 2 ]]; then
	usage
fi

main "$1" "$2"
