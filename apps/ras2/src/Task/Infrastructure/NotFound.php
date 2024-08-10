<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Ramona\Ras2\Task\Business\TaskId;
use RuntimeException;

final class NotFound extends RuntimeException
{
    public static function forId(TaskId $taskId): self
    {
        return new self("Task with ID '{$taskId}' was not found");
    }
}
