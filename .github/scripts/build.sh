#!/usr/bin/env bash
set -euo pipefail

declare -ra ssh_options=('-o' 'StrictHostKeyChecking=no' '-o' 'UserKnownHostsFile=/dev/null' '-i' './id_ed25519')

publish() {
	scp "${ssh_options[@]}" "$@"
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
		nix store diff-closures "$current_closure" "$new_closure" | sed 's#^\(.*\): \(.*\)$#<strong>\1</strong>: \2<br/>#'
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

		echo "$new_closure" >"$home_basename-home"

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

		echo "$new_closure" >"$host_basename-closure"

		make-row "$host_basename" "$new_closure" "$closure_diff"
	done
}

main() {
	local -r branch_name=$1
	local headers
	local output

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

		mapfile -t builds_hosts < <(nix eval --json '.#hosts.builds-hosts' | jq -c '.[]')

		for builds_host in "${builds_hosts[@]}"; do
			publish -- *-closure "root@$builds_host:/var/www/$builds_host.ibis-draconis.ts.net/builds/"
			publish -- *-home "root@$builds_host:/var/www/$builds_host.ibis-draconis.ts.net/builds/"

			ssh "${ssh_options[@]}" "root@$builds_host" -- "chmod a+r /var/www/$builds_host.ibis-draconis.ts.net/builds/*"

		done

		local closure
		local gcroot

		for filename in *-closure *-home; do
			closure=$(tr -d "\n" <"$filename")
			gcroot="/nix/var/nix/gcroots/$filename"

			for builds_host in "${builds_hosts[@]}"; do
				NIX_SSHOPTS="${ssh_options[*]}" nix-copy-closure --to "root@$builds_host" "$closure"

				ssh "${ssh_options[@]}" "root@$builds_host" -- "rm $gcroot; ln -s $closure $gcroot"
			done
		done
	fi
}

main "$1"
