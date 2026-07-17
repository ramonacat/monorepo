#!/usr/bin/env bash
set -euo pipefail

prettier --check .
tsc --build --noEmit
eslint
vite build
