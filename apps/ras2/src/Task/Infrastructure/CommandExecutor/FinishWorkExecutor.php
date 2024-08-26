<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\Clock;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<FinishWork>
 */
final class FinishWorkExecutor implements Executor
{
    public function __construct(
        private Repository $repository,
        private Clock $clock,
    ) {

    }

    public function execute(Command $command): void
    {
        $task = $this->repository->getById($command->taskId);

        if ($task instanceof Started) {
            $task = $task->toDone($this->clock->now());
        } elseif ($task instanceof BacklogItem) {
            $task = $task->toDone($command->userId);
        } else {
            throw InvalidTaskState::for($task);
        }

        $this->repository->save($task);
    }
}
