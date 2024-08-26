<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\Clock;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\ReturnToIdea;
use Ramona\Ras2\Task\Business\Idea;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<ReturnToIdea>
 */
final class ReturnToIdeaExecutor implements Executor
{
    public function __construct(
        private readonly Repository $repository,
        private readonly Clock $clock
    ) {
    }

    public function execute(Command $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $task = $this->repository->getById($command->taskId);
            if (! ($task instanceof Idea)) {
                $task = $task->toIdea($this->clock->now());
            }
            $this->repository->save($task);
        });
    }
}
