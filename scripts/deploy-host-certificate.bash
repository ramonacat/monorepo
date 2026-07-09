#!/usr/bin/env bash
set -euo pipefail

usage() {
	echo "$0 [hostname]"
}

declare certificate_path
declare certificate_key_path
certificate_path=$(mktemp)
certificate_key_path=$(mktemp)

cleanup() {
	rm "$certificate_path" || true
	rm "$certificate_key_path" || true
}

main() {
	local -r hostname="$1"
	local -r cert_json=$(VAULT_CAPATH=certificates VAULT_ADDR=https://vault.internal.ramona.fun \
		vault write pki-hosts/issue/hosts -format=json common_name="$hostname.devices.ramona.fun" ttl="24h")

	trap cleanup EXIT

	echo -n "$cert_json" | jq --raw-output '.data.certificate' >"$certificate_path"
	echo -n "$cert_json" | jq --raw-output '.data.private_key' >"$certificate_key_path"

	scp "$certificate_path" "root@$hostname:/var/ramona/identity/certificate.crt"
	scp "$certificate_key_path" "root@$hostname:/var/ramona/identity/certificate.key"

	ssh "root@$hostname" 'systemctl reset-failed vault-agent-main; systemctl restart vault-agent-main'
}

if [[ $# != 1 ]]; then
	usage
	exit 1
fi

main "$1"
