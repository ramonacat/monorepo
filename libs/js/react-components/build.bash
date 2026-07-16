#!/usr/bin/env bash
set -euo pipefail

rm -r dist/ || true
prettier --check .
tsc --build --noEmit
eslint
vite build
