<?php
declare(strict_types=1);

$configPath = getenv('DATABASE_CONFIG_TELEGRAF');
if ($configPath === false) {
    return [
        'dbname' => 'telegraf',
        'user' => 'ras2',
        'password' => 'ras2',
        'host' => 'localhost',
        'driver' => 'pdo_pgsql',
    ];
}

return require $configPath;