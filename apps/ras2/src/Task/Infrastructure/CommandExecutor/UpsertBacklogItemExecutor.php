<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<UpsertBacklogItem>
 * @psalm-suppress UnusedClass
 */
final readonly class UpsertBacklogItemExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(object $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $tags = $this->repository->fetchOrCreateTags($command->tags->toArray());
            $task = new BacklogItem(
                new TaskDescription($command->id, $command->title, new ArrayCollection($tags)),
                $command->assignee,
                $command->deadline
            );
            $this->repository->save($task);
        });
    }
}
