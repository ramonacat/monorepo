#!/usr/bin/env bash
set -euo pipefail

publish() {
	scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 "$@"
}

make-table() {
	local -r headers="$1"
	local -r body="$2"

	echo -e "<table><thead>$headers</thead><tbody>$body</tbody></table>"
}

make-row() {
	local -ra values=("$@")

	echo -e '<tr>'
	for value in "${values[@]}"; do
		echo -e "<td>$value</td>"
	done
	echo -e '</tr>'
}

diff-closures() {
	local -r current_filename="$1"
	local -r new_closure="$2"

	if current_closure=$(
		nix shell 'nixpkgs#curl' -c curl "https://hallewell.ibis-draconis.ts.net/builds/${current_filename}" 2>/dev/null | tr -d '[:space:]'
	); then
		nix store diff-closures "$current_closure" "$new_closure" | sed 's/^\(.*\): \(.*\)$/**\1**: \2/'
	else
		echo "failed to receive current closure"
	fi
}

make-rows-homes() {
	local home_basename
	local new_closure
	local closure_diff

	for f in result/homes/*; do
		home_basename=$(basename "$f")
		new_closure=$(readlink "$f")
		closure_diff=$(diff-closures "$home_basename-home" "$new_closure")

		make-row "$home_basename" "$new_closure" "$closure_diff"
	done
}

make-rows-hosts() {
	local host_basename
	local new_closure
	local closure_diff

	for f in result/hosts/*; do
		host_basename=$(basename "$f")
		new_closure=$(readlink "$f")
		closure_diff=$(diff-closures "$host_basename-closure" "$new_closure")

		make-row "$host_basename" "$new_closure" "$closure_diff"
	done
}

declare -r branch_name=$1
declare headers
declare output

output=$"# Build results\n## Homes\n"
headers=$(make-row "name" "closure" "diff")

nix build -L -v ".#everything"

output+=$(make-table "$headers" "$(make-rows-homes)")
output+=$(make-table "$headers" "$(make-rows-hosts)")

{
	echo "READABLE_OUTPUT<<EOF"
	echo -e "$output"
	echo "EOF"
} >>"$GITHUB_OUTPUT"

{
	echo -e "$output"
} >>"$GITHUB_STEP_SUMMARY"

if [[ "$branch_name" == "main" ]]; then
	publish -- result/iso/iso/*.iso root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/nixos-latest.iso
	publish -- result/kexec-bundle/* root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/kexec-bundle
	publish -- *-closure root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/
	publish -- *-home root@hallewell:/var/www/hallewell.ibis-draconis.ts.net/builds/

	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@hallewell -- "chmod a+r /var/www/hallewell.ibis-draconis.ts.net/builds/*"

	declare closure
	declare gcroot

	for filename in *-closure *-home; do
		closure=$(tr -d "\n" <"$filename")
		gcroot="/nix/var/nix/gcroots/$filename"

		ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_ed25519 root@hallewell -- "rm $gcroot; ln -s $closure $gcroot"
	done
fi
