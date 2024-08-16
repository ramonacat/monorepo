<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Application\Query\ByToken;
use Ramona\Ras2\User\Application\Session;

/**
 * @implements Executor<Session, ByToken>
 */
class FindByTokenExecutorMock implements Executor
{
    public function __construct(
        private \Closure $callback
    ) {
    }

    public function execute(Query $query): mixed
    {
        return ($this->callback)();
    }
}
