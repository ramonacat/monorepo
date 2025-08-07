#!/usr/bin/env bash

set -euo pipefail

populate-ssh-keys() {
	local -r secrets_path=$1
	local -r hostname=$2

	pushd "$secrets_path" >/dev/null || {
		echo "$secrets_path could not be opened"
		exit 1
	}

	local -r rsa_key=$(agenix -d "$hostname-ssh-host-key-rsa.age")
	local -r ed25519_key=$(agenix -d "$hostname-ssh-host-key-ed25519.age")

	popd >/dev/null || {
		echo "failed to leave $secrets_path"
		exit 1
	}

	mkdir --parents etc/ssh/

	echo "$ed25519_key" >etc/ssh/ssh_host_ed25519_key
	echo "$rsa_key" >etc/ssh/ssh_host_rsa_key

	chmod 0600 etc/ssh/ssh_host*

	ssh-keygen -f etc/ssh/ssh_host_ed25519_key -y >etc/ssh/ssh_host_ed25519_key.pub
	ssh-keygen -f etc/ssh/ssh_host_rsa_key -y >etc/ssh/ssh_host_rsa_key.pub
}
