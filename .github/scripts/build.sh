#!/usr/bin/env bash
set -x
set -euo pipefail

function publish {
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 "$@"
}

BRANCH_NAME=$1

nix build -L -v ".#everything"

for f in result/hosts/*; do
    host_basename=$(basename "$f")
    readlink "$f" > "$host_basename-closure"
done

echo "On branch: $BRANCH_NAME"
if [[ "$BRANCH_NAME" == "main" ]]; then
    publish -- result/iso/iso/*.iso root@blackwood:/var/www/ramona.fun/builds/nixos-latest.iso
    publish -- result/kexec-bundle/* root@blackwood:/var/www/ramona.fun/builds/kexec-bundle
    publish -- *-closure root@blackwood:/var/www/ramona.fun/builds/

    for filename in *-closure; do
        CLOSURE=$(tr -d "\n" < "$filename")
        GCROOT="/nix/var/nix/gcroots/$filename"

        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@blackwood -- "rm $GCROOT; ln -s $CLOSURE $GCROOT"
    done
fi

cat ./*-closure

