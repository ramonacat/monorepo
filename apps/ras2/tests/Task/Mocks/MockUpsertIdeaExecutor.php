<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;

/**
 * @implements Executor<UpsertIdea>
 */
final class MockUpsertIdeaExecutor implements Executor
{
    public ?UpsertIdea $command;

    public function execute(Command $command): void
    {
        $this->command = $command;
    }
}
