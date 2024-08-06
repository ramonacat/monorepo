<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\CQRS\Query\Mocks;

use Ramona\Ras2\CQRS\Query\Executor;
use Ramona\Ras2\CQRS\Query\Query;

/**
 * @implements Executor<string, MockQuery>
 */
final class MockQueryExecutor implements Executor
{
    public function execute(Query $query): mixed
    {
        return $query->value;
    }
}
