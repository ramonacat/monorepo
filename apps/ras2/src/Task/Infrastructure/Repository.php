<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\Task\Business\Task;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Business\UserId;

interface Repository
{
    public function save(Task $task): void;

    /**
     * @param array<int, string> $tags
     * @return array<int, TagId>
     */
    public function fetchOrCreateTags(array $tags): array;

    /**
     * @param \Closure():void $action
     */
    public function transactional(\Closure $action): void;

    public function getById(TaskId $taskId): Task;

    /**
     * @return ArrayCollection<int, Started>
     */
    public function findStartedTasks(UserId $userId): ArrayCollection;
}