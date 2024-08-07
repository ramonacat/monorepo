<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;

/**
 * @implements Executor<MockCommand>
 */
final class MockCommandExecutor implements Executor
{
    public ?Command $receivedCommand = null;

    public function execute(Command $command): void
    {
        $this->receivedCommand = $command;
    }
}
