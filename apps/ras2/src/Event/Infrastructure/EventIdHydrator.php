<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure;

use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @implements ValueHydrator<EventId>
 */
final class EventIdHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        return EventId::fromString($input);
    }

    public function handles(): string
    {
        return EventId::class;
    }
}
