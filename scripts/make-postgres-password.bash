#!/usr/bin/env bash
set -euo pipefail

usage() {
	echo "usage: $0 [name] [username] [target-namespace] [password-key?]" >&2
	exit 1
}

main() {
	local -r name="$1"
	local -r username="$2"
	local -r target_namespace="$3"
	local -r password_key="${4:-password}"
	local -r password=$(tr -dc 'A-Za-z0-9!?%=' </dev/urandom | head -c 10)

	kubeseal -oyaml <<EOF
        apiVersion: v1
        data:
          username: $(echo -n "$username" | base64)
          password: $(echo -n "$password" | base64)
        kind: Secret
        metadata:
          name: $name
          namespace: cloudnative-pg-database
          labels:
            cnpg.io/reload: "true"
        type: kubernetes.io/basic-auth
EOF
	kubeseal -oyaml <<EOF
        apiVersion: v1
        data:
          username: $(echo -n "$username" | base64)
          ${password_key}: $(echo -n "$password" | base64)
        kind: Secret
        metadata:
          name: $name
          namespace: $target_namespace
          labels:
            cnpg.io/reload: "true"
        type: kubernetes.io/basic-auth
EOF
}

if [[ $# != 3 ]]; then
	usage
fi

main "$@"
