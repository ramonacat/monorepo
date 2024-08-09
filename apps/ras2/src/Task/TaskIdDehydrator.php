<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ValueDehydrator;

/**
 * @implements ValueDehydrator<TaskId>
 */
final class TaskIdDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return (string) $value;
    }

    public function handles(): string
    {
        return TaskId::class;
    }
}
