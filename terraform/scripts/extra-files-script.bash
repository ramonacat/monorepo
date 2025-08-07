#!/usr/bin/env bash

set -euo pipefail

source "$RAMONA_FLAKE_ROOT"/scripts/lib/populate-ssh-keys.bash

populate-ssh-keys "$RAMONA_FLAKE_ROOT/secrets/" "$HOSTNAME"
