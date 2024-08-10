<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\ClockInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<StartWork>
 */
final class StartWorkExecutor implements Executor
{
    public function __construct(
        private Repository $repository,
        private ClockInterface $clock
    ) {
    }

    public function execute(Command $command): void
    {
        $this->repository->transactional(function () use ($command) {
            foreach ($this->repository->findStartedTasks($command->userId) as $task) {
                $task = $task->toBacklog($this->clock->now());
                $this->repository->save($task);
            }

            $task = $this->repository->getById($command->taskId);
            if (($task instanceof BacklogItem)) {
                $task = $task->toStarted($command->userId, $this->clock->now());
            } elseif ($task instanceof Started) {
                $task->startRecordingTime($this->clock->now());
            }

            $this->repository->save($task);
        });
    }
}
