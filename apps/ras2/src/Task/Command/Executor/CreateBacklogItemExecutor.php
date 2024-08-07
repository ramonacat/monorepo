<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\BacklogItem;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Repository;
use Ramona\Ras2\Task\TaskDescription;

/**
 * @implements Executor<UpsertBacklogItem>
 * @psalm-suppress UnusedClass
 */
final readonly class CreateBacklogItemExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(object $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $tags = $this->repository->fetchOrCreateTags($command->tags->toArray());
            $task = new BacklogItem(new TaskDescription(
                $command->id,
                $command->title,
                new ArrayCollection($tags)
            ), $command->assignee);
            $this->repository->save($task);
        });
    }
}
