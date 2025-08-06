#!/usr/bin/env bash
set -x
set -euo pipefail

mkdir -p ~/.config/git/
cat >~/.config/git/config <<EOF
[credential "https://git.lix.systems"]
      username = "ramonacat"
      helper = "!f() { test \"\$1\" = get && echo \"password=$LIX_REPO_TOKEN\"; }; f"
EOF
