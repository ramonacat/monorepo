#!/usr/bin/env bash
set -x
set -euo pipefail

function publish {
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 "$@"
}

BRANCH_NAME=$1

nix build -L -v ".#everything"

OUTPUT=$"# Build results\n## Homes\n<table><thead><tr><th>name</th><th>closure</th><th>diff</th></tr></thead><tbody>"

for f in result/homes/*; do
    home_basename=$(basename "$f")
    readlink "$f" > "$home_basename-home"

    OUTPUT=$"$OUTPUT\n<tr><td>$home_basename</td><td>$(readlink "$f")</td>"

    echo "diff for $home_basename"
    CURRENT_CLOSURE=$(nix shell 'nixpkgs#curl' -c curl "https://hallewell.ibis-draconis.ts.net/builds/$home_basename-home" | tr -d '[:space:]' || true)

    DIFF=""
    # This is a bit of a hack, a 404 will result in the response being HTML, so it will not start with a `/`
    if [[ "${CURRENT_CLOSURE:0:1}" = "/" ]]; then
        DIFF=$(nix store diff-closures "$CURRENT_CLOSURE" "$f" | sed 's/^\(.*\): \(.*\)$/**\1**: \2/')
    fi

    OUTPUT=$"$OUTPUT <td>${DIFF//$'\n'/\<br\/\>}</td></tr>"
done

OUTPUT=$"$OUTPUT </tbody></table>"

OUTPUT=$"$OUTPUT\n\n## Systems\n<table><thead><tr><th>name</th><th>closure</th><th>diff</th></tr></thead><tbody>"

for f in result/hosts/*; do
    host_basename=$(basename "$f")
    readlink "$f" > "$host_basename-closure"

    OUTPUT=$"$OUTPUT\n<tr><td>$host_basename</td><td>$(readlink "$f")</td>"

    echo "diff for $host_basename"
    CURRENT_CLOSURE=$(nix shell 'nixpkgs#curl' -c curl "https://hallewell.ibis-draconis.ts.net/builds/$host_basename-closure" | tr -d '[:space:]' || true)

    DIFF=""
    # This is a bit of a hack, a 404 will result in the response being HTML, so it will not start with a `/`
    if [[ "${CURRENT_CLOSURE:0:1}" = "/" ]]; then
        DIFF=$(nix store diff-closures "$CURRENT_CLOSURE" "$f" | sed 's/^\(.*\): \(.*\)$/**\1**: \2/')
    fi

    OUTPUT=$"$OUTPUT <td>${DIFF//$'\n'/\<br\/\>}</td></tr>"
done

OUTPUT=$"$OUTPUT </tbody></table>"

{
echo "READABLE_OUTPUT<<EOF"
echo -e "$OUTPUT"
echo "EOF"
} >> "$GITHUB_OUTPUT"

{
echo -e "$OUTPUT"
} >> "$GITHUB_STEP_SUMMARY"

echo "On branch: $BRANCH_NAME"
if [[ "$BRANCH_NAME" == "main" ]]; then
    publish -- result/iso/iso/*.iso root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/nixos-latest.iso
    publish -- result/kexec-bundle/* root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/kexec-bundle
    publish -- *-closure root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/
    publish -- *-home root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@hallewell -- "chmod a+r /var/www/hallewell.ibis-draconis.ts.net/builds/*"

    for filename in *-closure *-home; do
        CLOSURE=$(tr -d "\n" < "$filename")
        GCROOT="/nix/var/nix/gcroots/$filename"

        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@hallewell -- "rm $GCROOT; ln -s $CLOSURE $GCROOT"
    done
fi

cat ./*-closure
cat ./*-home
