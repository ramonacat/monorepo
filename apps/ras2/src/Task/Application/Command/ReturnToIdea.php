<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\ReturnToIdeaExecutor;

#[ExecutedBy(ReturnToIdeaExecutor::class), APICommand('tasks', 'return-to-idea')]
final readonly class ReturnToIdea implements Command
{
    public function __construct(
        public TaskId $taskId
    ) {
    }
}
