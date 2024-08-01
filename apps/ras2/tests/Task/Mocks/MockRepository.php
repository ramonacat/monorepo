<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Ramona\Ras2\Task\Repository;
use Ramona\Ras2\Task\Task;

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
}
