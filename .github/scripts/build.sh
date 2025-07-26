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

    echo "diff for $host_basename"
    CURRENT_CLOSURE=$(nix shell 'nixpkgs#curl' -c curl "https://hallewell.ibis-draconis.ts.net/builds/$host_basename-closure" | tr -d '[:space:]')
    nix store diff-closures "$CURRENT_CLOSURE" "$f"

    echo
done

echo "On branch: $BRANCH_NAME"
if [[ "$BRANCH_NAME" == "main" ]]; then
    publish -- result/iso/iso/*.iso root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/nixos-latest.iso
    publish -- result/kexec-bundle/* root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/kexec-bundle
    publish -- *-closure root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/

    for filename in *-closure; do
        CLOSURE=$(tr -d "\n" < "$filename")
        GCROOT="/nix/var/nix/gcroots/$filename"

        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@hallewell -- "rm $GCROOT; ln -s $CLOSURE $GCROOT"
    done
fi

cat ./*-closure

