<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Ramona\Ras2\Task\Business\Task;
use Ramona\Ras2\Task\Infrastructure\Repository;

final class MockRepository implements Repository
{
    /**
     * @var list<Task>
     */
    private array $tasks;

    public function save(Task $task): void
    {
        $this->tasks[] = $task;
    }

    /**
     * @return list<Task>
     */
    public function tasks(): array
    {
        return $this->tasks;
    }

    public function fetchOrCreateTags(array $tags): array
    {
        return [];
    }

    public function transactional(\Closure $action): void
    {
        ($action)();
    }
}
