<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

use Doctrine\DBAL\Connection;

final class PostgresRepository implements Repository
{
    public function __construct(
        private Connection $databaseConnection
    ) {
    }

    public function transactional(\Closure $callable): void
    {
        $this->databaseConnection->transactional($callable);
    }

    public function save(User $user): void
    {
        $this->databaseConnection->executeStatement('
            INSERT INTO 
                users(id, name) 
            VALUES(:id, :name)
            ON CONFLICT (id) DO UPDATE SET name = :name
        ', [
            'id' => (string) $user->id(),
            'name' => $user->name(),
        ]);
    }
}
