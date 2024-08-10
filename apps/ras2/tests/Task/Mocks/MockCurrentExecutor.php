<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\CurrentTaskView;

/**
 * @implements Executor<?CurrentTaskView, Current>
 */
final class MockCurrentExecutor implements Executor
{
    public ?Current $query = null;

    public function __construct(
        private ?CurrentTaskView $result
    ) {
    }

    public function execute(Query $query): mixed
    {
        $this->query = $query;
        return $this->result;
    }
}
