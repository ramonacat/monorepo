<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Application\Query\FindRandom;
use Ramona\Ras2\Task\Application\TaskView;

/**
 * @implements Executor<ArrayCollection<int, TaskView>, FindRandom>
 */
final class MockFindRandomExecutor implements Executor
{
    public ?FindRandom $query = null;

    /**
     * @param list<TaskView> $result
     */
    public function __construct(
        private array $result = []
    ) {
    }

    public function execute(Query $query): mixed
    {
        $this->query = $query;

        return new ArrayCollection($this->result);
    }
}
