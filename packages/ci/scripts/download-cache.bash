#!/usr/bin/env bash

set -euo pipefail

cache_key="$1"

if rclone copy "default:ramona-woodpecker-cache/$cache_key.tar.gz" /tmp/ && [[ -f "/tmp/$cache_key.tar.gz" ]]; then
	tar zxf "/tmp/$cache_key.tar.gz"
fi
