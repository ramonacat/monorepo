<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Query\Executor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Query\FindByToken;
use Ramona\Ras2\User\Session;
use Ramona\Ras2\User\UserId;
use Ramona\Ras2\User\UserNotFound;

/**
 * @implements Executor<Session, FindByToken>
 */
final class FindByTokenExecutor implements Executor
{
    public function __construct(
        private Connection $databaseConnection
    ) {
    }

    public function execute(Query $query): mixed
    {
        /** @var string|false $userId */
        $userId = $this->databaseConnection->fetchOne('SELECT id FROM user_tokens WHERE token=:token', [$query->token]);

        if ($userId === false) {
            throw UserNotFound::withToken();
        }

        /** @var array{id: string, name: string}|false $rawUser */
        $rawUser = $this->databaseConnection->fetchAssociative('SELECT id, name FROM users WHERE id=:id', [
            'id' => $userId,
        ]);
        if ($rawUser === false) {
            throw UserNotFound::withToken();
        }

        return new Session(UserId::fromString($rawUser['id']), $rawUser['name']);
    }
}
