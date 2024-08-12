<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\ClockInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\ReturnToBacklog;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<ReturnToBacklog>
 */
final class ReturnToBacklogExecutor implements Executor
{
    public function __construct(
        private Repository $repository,
        private ClockInterface $clock
    ) {
    }

    public function execute(Command $command): void
    {
        $task = $this->repository->getById($command->taskId);
        if (! ($task instanceof Started)) {
            throw InvalidTaskState::for($task);
        }

        $backlogTask = $task->toBacklog($this->clock->now());

        $this->repository->save($backlogTask);
    }
}
