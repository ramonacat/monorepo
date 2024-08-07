<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

/**
 * @implements Executor<string, MockQuery>
 */
final class MockQueryExecutor implements Executor
{
    /**
     * @param MockQuery $query
     */
    public function execute(Query $query): mixed
    {
        return $query->value;
    }
}
