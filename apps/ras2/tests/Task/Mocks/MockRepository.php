<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Closure;
use Doctrine\Common\Collections\ArrayCollection;
use Exception;
use Ramona\Ras2\Task\Business\Task;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\User\Business\UserId;

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

    public function fetchOrCreateTags(ArrayCollection $tags): ArrayCollection
    {
        return new ArrayCollection();
    }

    public function transactional(Closure $action): void
    {
        ($action)();
    }

    public function getById(TaskId $taskId): Task
    {
        throw new Exception('NOT IMPLEMENTED');
    }

    public function findStartedTasks(UserId $userId): ArrayCollection
    {
        throw new Exception('NOT IMPLEMENTED');
    }
}
