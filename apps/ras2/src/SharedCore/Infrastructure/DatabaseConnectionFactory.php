<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Doctrine\DBAL\Connection;
use Doctrine\DBAL\DriverManager;

final class DatabaseConnectionFactory
{
    public static function create(string $databaseName): Connection
    {
        $config = $databaseName === 'ras2'
            ? require __DIR__ . '/../../../migrations-db.php'
            : require __DIR__ . '/../../../' . $databaseName . '-db.php';

        return DriverManager::getConnection($config);
    }
}
