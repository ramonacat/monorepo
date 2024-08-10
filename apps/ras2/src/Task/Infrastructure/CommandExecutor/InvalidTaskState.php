<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\Task\Business\Task;
use RuntimeException;

final class InvalidTaskState extends RuntimeException
{
    public static function for(Task $task): self
    {
        $state = get_class($task);
        return new self("Task {$task->id()} is in unexpected state: {$state}");
    }
}
