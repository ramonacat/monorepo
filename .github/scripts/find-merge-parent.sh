#!/usr/bin/env bash

parents=$(git log --pretty=%P -n1 "$GITHUB_SHA")
change_parent=${parents#* }

echo "parent=$change_parent" >>"$GITHUB_OUTPUT"
echo "parent=$change_parent"
