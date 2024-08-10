<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;

/**
 * @template T of Command
 * @implements Executor<T>
 */
final class MockExecutor implements Executor
{
    /**
     * @var ?T
     */
    public ?Command $command;

    public function execute(Command $command): void
    {
        $this->command = $command;
    }
}
