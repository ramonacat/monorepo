<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\Task\Business\TaskId;

final readonly class ReturnToIdea implements Command
{
    public function __construct(
        public TaskId $taskId
    ) {
    }
}
