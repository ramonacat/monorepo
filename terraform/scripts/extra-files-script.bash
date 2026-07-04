#!/usr/bin/env bash

set -euo pipefail

source "$RAMONA_FLAKE_ROOT"/scripts/lib/populate-ssh-keys.bash

populate-ssh-keys "$RAMONA_FLAKE_ROOT/secrets/" "$HOSTNAME"

mkdir -p var/ramona/tailscale/

echo -n "$TAILNET_KEY" >var/ramona/tailscale/key

mkdir -p var/ramona/identity/

echo -n "$CERTIFICATE" > var/ramona/identity/certificate.crt
echo -n "$CERTIFICATE_KEY" > var/ramona/identity/certificate.key
