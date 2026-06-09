#!/usr/bin/env bash

git config --global user.email "update@ramona.fun"
git config --global user.name "automated update"

echo "base: $GITHUB_BASE_REF"

changed_apps=$(git diff --name-only "origin/$GITHUB_BASE_REF" | grep -oP '(?<=^apps/)(.*)(?=/.*)')

echo -e "changed:\n$changed_apps"

while IFS= read -r line; do
	if [[ -z "$line" ]]; then
		continue
	fi

	if grep -q "vendorHash" "packages/$line.nix"; then
		build_output=$(nix build ".#packages.x86_64-linux.$line" 2>&1)
		echo -e "$line:\n$build_output"

		specified_hash=$(echo "$build_output" | grep 'specified:' | sed -E 's#\s*specified:\s*(.*)\s*#\1#')
		new_hash=$(echo "$build_output" | grep 'got:' | sed -E 's#\s*got:\s*(.*)\s*#\1#')

		replaced=$(cat "packages/$line.nix" | python -c "import sys;print(sys.stdin.read().replace('$specified_hash', '$new_hash'))")
		echo "$replaced" >"packages/$line.nix"

		# TODO do something about the duplicated logic
		build_output=$(nix build ".#packages.x86_64-linux.$line-coverage" 2>&1)
		echo -e "$line-coverage:\n$build_output"

		specified_hash=$(echo "$build_output" | grep 'specified:' | sed -E 's#\s*specified:\s*(.*)\s*#\1#')
		new_hash=$(echo "$build_output" | grep 'got:' | sed -E 's#\s*got:\s*(.*)\s*#\1#')

		replaced=$(cat "packages/$line.nix" | python -c "import sys;print(sys.stdin.read().replace('$specified_hash', '$new_hash'))")
		echo "$replaced" >"packages/$line.nix"

		git commit -am"packages/$line: update vendorHash"
	fi

	git push
done < <(echo -en "$changed_apps\n")
