<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrateFromSession;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\StartWorkExecutor;
use Ramona\Ras2\User\Business\UserId;

#[ExecutedBy(StartWorkExecutor::class), APICommand('tasks', 'start-work')]
final readonly class StartWork implements Command
{
    public function __construct(
        public TaskId $taskId,
        #[HydrateFromSession('userId')]
        public UserId $userId
    ) {
    }
}
