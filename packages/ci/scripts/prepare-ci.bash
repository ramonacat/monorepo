#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/nix/
mkdir -p ~/.ssh/
mkdir -p ~/.config/rclone/

attic login main https://attic.infrastructure.ramona.fun/ "$ATTIC_TOKEN"
attic use main

echo "extra-experimental-features = flakes nix-command" >>/etc/nix/nix.conf
echo "$SSH_KEY" >~/.ssh/id_ed25519 && chmod 0600 ~/.ssh/id_ed25519 && ssh-keygen -y -f ~/.ssh/id_ed25519 >~/.ssh/id_ed25519.pub

cat >~/.config/rclone/rclone.conf <<-EOT
	[default]
	type=s3
	provider=Hetzner
	access_key_id=$ACCESS_KEY_ID
	secret_access_key=$SECRET_ACCESS_KEY
	region=nbg1
	endpoint=nbg1.your-objectstorage.com
EOT

echo "$GITHUB_TOKEN" | skopeo login --username ramonacat --password-stdin ghcr.io
echo "$FORGEJO_TOKEN" | skopeo login --username ramona --password-stdin code.ramona.fun
