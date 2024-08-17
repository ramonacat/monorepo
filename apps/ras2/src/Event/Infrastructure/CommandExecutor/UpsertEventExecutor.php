<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure\CommandExecutor;

use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Business\Event;
use Ramona\Ras2\Event\Infrastructure\Repository;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;

/**
 * @implements Executor<UpsertEvent>
 */
final readonly class UpsertEventExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(Command $command): void
    {
        $event = new Event($command->id, $command->title, $command->startTime, $command->endTime, $command->attendees);
        $this->repository->save($event);
    }
}
