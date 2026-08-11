#!/usr/bin/env bash

set -euo pipefail

cache_key="$1"
directory="$2"

if [[ -d "$directory" ]]; then
	rm "/tmp/$cache_key.tar.gz" || true
	tar czf "/tmp/$cache_key.tar.gz" "$directory"

	rclone copy "/tmp/$cache_key.tar.gz" default:ramona-woodpecker-cache/
fi
