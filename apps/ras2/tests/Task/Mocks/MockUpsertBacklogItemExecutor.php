<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;

/**
 * @implements Executor<UpsertBacklogItem>
 */
final class MockUpsertBacklogItemExecutor implements Executor
{
    public ?UpsertBacklogItem $command;

    public function execute(Command $command): void
    {
        $this->command = $command;
    }
}
