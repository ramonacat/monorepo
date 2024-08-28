<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\PauseWorkExecutor;

#[ExecutedBy(PauseWorkExecutor::class)]
final class PauseWork implements Command
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public TaskId $taskId
    ) {
    }
}
