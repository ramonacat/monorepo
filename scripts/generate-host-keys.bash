#!/usr/bin/env bash

set -euo pipefail

usage() {
	echo "usage: $0 [secrets-path] [hostname]" >&2

	exit 1
}

main() {
	local -r secrets_path=$1
	local -r hostname=$2

	local -r keys_temp=$(mktemp --directory)

	ssh-keygen -N '' -qt rsa -f "$keys_temp/id_rsa"
	ssh-keygen -N '' -qt ed25519 -f "$keys_temp/id_ed25519"

	pushd "$secrets_path" >/dev/null
	agenix -e "$hostname-ssh-host-key-rsa.age" >/dev/null <"$keys_temp/id_rsa"
	agenix -e "$hostname-ssh-host-key-ed25519.age" >/dev/null <"$keys_temp/id_ed25519"

	echo "$hostname = {"
	echo "rsa = \"$(cat "$keys_temp/id_rsa.pub")\";"
	echo "ed25519 = \"$(cat "$keys_temp/id_ed25519.pub")\";"
	echo "};"

	rm -r "$keys_temp"
	popd >/dev/null
}

if [[ $# -ne 2 ]]; then
	usage
fi

main "$1" "$2"
