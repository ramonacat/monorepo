<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Ramona\Ras2\Task\Business\TaskId;
use RuntimeException;

final class MissingAssignee extends RuntimeException
{
    public static function for(TaskId $taskId): self
    {
        return new self("Task with ID '{$taskId}' is missing an assignee");
    }
}
