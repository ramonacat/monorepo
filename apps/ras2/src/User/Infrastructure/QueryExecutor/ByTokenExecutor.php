<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Infrastructure\QueryExecutor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Application\Query\ByToken;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\UserId;
use Ramona\Ras2\User\Infrastructure\UserNotFound;

/**
 * @implements Executor<Session, ByToken>
 */
final class ByTokenExecutor implements Executor
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

        $rawUser = $this->databaseConnection->fetchAssociative('SELECT id, name, timezone FROM users WHERE id=:id', [
            'id' => $userId,
        ]);
        if ($rawUser === false) {
            throw UserNotFound::withToken();
        }

        return new Session(UserId::fromString($rawUser['id']), $rawUser['name'], new \DateTimeZone(
            $rawUser['timezone']
        ));
    }
}
