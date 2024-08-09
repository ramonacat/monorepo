<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ValueHydrator;

/**
 * @implements ValueHydrator<TaskId>
 */
final class TaskIdHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        assert(is_string($input));
        return TaskId::fromString($input);
    }

    public function handles(): string
    {
        return TaskId::class;
    }
}
