#!/usr/bin/env bash

set -euo pipefail
set -x

if [[ "${1:-}" == "--no-fix" ]]; then
  php ./vendor/bin/ecs
else
  php ./vendor/bin/ecs --fix
fi
php ./vendor/bin/phpstan.phar
php ./vendor/bin/phpunit
php ./vendor/bin/infection --min-msi=73 --min-covered-msi=100 -j"$(nproc)"
