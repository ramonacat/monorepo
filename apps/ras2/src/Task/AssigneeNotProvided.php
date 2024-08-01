<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use RuntimeException;

final class AssigneeNotProvided extends RuntimeException
{
    public static function forTask(TaskId $id): self
    {
        return new self("Assignee was not provided when changing state for task \"{$id}\"");
    }
}
