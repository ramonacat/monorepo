<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;

/**
 * @implements ValueHydrator<TaskView>
 */
final class TaskViewHydrator implements ValueHydrator
{
    /**
     * @psalm-suppress MixedArrayAccess
     * @psalm-suppress MixedArgument
     * @psalm-suppress MixedArgumentTypeCoercion
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        return new TaskView(
            TaskId::fromString($input['id']),
            $input['title'],
            $input['assignee_name'],
            new ArrayCollection($input['tags']),

            // TODO: Date/time in database should also be stored
            //   in the [timestamp, timezone] format, so this is coherent with dehydration
            $input['deadline'] === null
                ? null
                : \Safe\DateTimeImmutable::createFromFormat('Y-m-d H:i:sP', $input['deadline']),
            new ArrayCollection(array_map(fn ($x) => $hydrator->hydrate(TimeRecord::class, $x), $input['time_records']))
        );
    }

    public function handles(): string
    {
        return TaskView::class;
    }
}
