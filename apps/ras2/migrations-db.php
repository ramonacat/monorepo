<?php

$configPath = getenv('DATABASE_CONFIG');
if ($configPath === false) {
    return [
        'dbname' => 'ras2',
        'user' => 'ras2',
        'password' => 'ras2',
        'host' => 'localhost',
        'driver' => 'pdo_pgsql',
    ];
}

return require $configPath;