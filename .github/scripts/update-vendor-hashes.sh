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
		sed -Ei 's#(\s*vendorHash\s*=\s*)".*"(.*)#\1""\2#' "packages/$line.nix"
		new_hash=$(nix build ".#packages.x86_64-linux.$line" 2>&1 | grep 'got:' | sed -E 's#\s*got:\s*(.*)\s*#\1#')
		sed -Ei "s#(\\s*vendorHash\\s*=\\s*)\".*\"(.*)#\1\"$new_hash\"\2#" "packages/$line.nix"

		git commit -am"packages/$line: update vendorHash"
	fi

	git push
done < <(echo -en "$changed_apps\n")
