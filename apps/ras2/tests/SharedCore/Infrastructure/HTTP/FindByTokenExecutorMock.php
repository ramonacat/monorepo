<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Query\FindByToken;
use Ramona\Ras2\User\Session;
use Ramona\Ras2\User\UserId;

/**
 * @implements Executor<Session, FindByToken>
 */
class FindByTokenExecutorMock implements Executor
{
    public function __construct(
        private UserId $userId,
        private string $username
    ) {
    }

    public function execute(Query $query): mixed
    {
        return new Session($this->userId, $this->username);
    }
}
