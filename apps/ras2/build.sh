#!/usr/bin/env bash

set -euo pipefail
set -x

gulp
if [[ "${1:-}" == "--no-fix" ]]; then
  php ./vendor/bin/ecs
else
  php ./vendor/bin/ecs --fix
fi
php ./vendor/bin/phpstan.phar
php ./vendor/bin/psalm.phar --no-cache
php ./vendor/bin/psalm.phar --no-cache --taint-analysis
php ./vendor/bin/phpunit
php ./vendor/bin/infection --min-msi=42 --min-covered-msi=100 -j"$(nproc)"
