<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Doctrine\DBAL\Connection;
use Doctrine\DBAL\DriverManager;

final class DatabaseConnectionFactory
{
    public static function create(): Connection
    {
        $config = require __DIR__ . '/../../../migrations-db.php';

        return DriverManager::getConnection($config);
    }
}
