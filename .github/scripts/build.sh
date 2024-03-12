#!/usr/bin/env bash
set -x
set -euo pipefail

BRANCH_NAME=$1

function build_closure() {
    HOSTNAME=$1

    nix build ".#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel"
    readlink result > "${HOSTNAME}-closure"
}

build_closure "ananas"
build_closure "angelsin"
build_closure "caligari"
build_closure "evillian"
build_closure "hallewell"
build_closure "moonfall"
build_closure "shadowmend"

echo "On branch: $BRANCH_NAME"
if [[ "$BRANCH_NAME" == "main" ]]; then
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 -- *-closure root@caligari:/var/www/ramona.fun/builds/
    for filename in *-closure; do
        CLOSURE=$(tr -d "\n" < "$filename")
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@caligari -- "ln -s $CLOSURE /nix/var/nix/gcroots/$filename"
    done
fi

cat ./*-closure
