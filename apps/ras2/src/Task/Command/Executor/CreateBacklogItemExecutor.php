<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command\Executor;

use Ramona\Ras2\Task\BacklogItem;
use Ramona\Ras2\Task\Command\CreateBacklogItem;
use Ramona\Ras2\Task\Repository;
use Ramona\Ras2\Task\TaskDescription;

/**
 * @implements Executor<CreateBacklogItem>
 * @psalm-suppress UnusedClass
 */
final class CreateBacklogItemExecutor implements Executor
{
    private Repository $repository;

    public function __construct(Repository $repository)
    {
        $this->repository = $repository;
    }

    public function execute(object $command): void
    {
        $task = new BacklogItem(new TaskDescription(
            $command->id,
            $command->categoryId,
            $command->title,
            $command->tags
        ), $command->assignee);
        $this->repository->save($task);
    }
}
