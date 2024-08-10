<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Infrastructure;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\User\Business\Token;
use Ramona\Ras2\User\Business\User;

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

    public function assignTokenByUsername(string $name, Token $token): void
    {
        $this->databaseConnection->transactional(function () use ($name, $token) {
            $userId = $this
                ->databaseConnection
                ->executeQuery('SELECT id FROM users WHERE name=:name', [
                    'name' => $name,
                ])
                ->fetchOne();

            assert(is_string($userId) || $userId === false);

            if ($userId === false) {
                throw UserNotFound::forName($name);
            }

            $this->databaseConnection->executeStatement('
            INSERT INTO user_tokens(id, token) 
            VALUES (
                :id, :value
            )
        ', [
                'id' => $userId,
                'value' => (string) $token,
            ]);
        });
    }
}
