<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\FinishWorkExecutor;
use Ramona\Ras2\User\Business\UserId;

#[ExecutedBy(FinishWorkExecutor::class), APICommand('tasks', 'finish-work')]
final class FinishWork implements Command
{
    public function __construct(
        public TaskId $taskId,
        public UserId $userId
    ) {
    }
}
