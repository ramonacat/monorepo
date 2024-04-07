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
build_closure "shadowsoul"
nix build .#nixosConfigurations.iso.config.system.build.isoImage --out-link iso

echo "On branch: $BRANCH_NAME"
if [[ "$BRANCH_NAME" == "main" ]]; then
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 -- iso/iso/*.iso root@caligari:/var/www/ramona.fun/builds/nixos-latest.iso
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 -- *-closure root@caligari:/var/www/ramona.fun/builds/
    for filename in *-closure; do
        CLOSURE=$(tr -d "\n" < "$filename")
        GCROOT="/nix/var/nix/gcroots/$filename"

        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@caligari -- "rm $GCROOT; ln -s $CLOSURE $GCROOT"
    done
fi

cat ./*-closure

