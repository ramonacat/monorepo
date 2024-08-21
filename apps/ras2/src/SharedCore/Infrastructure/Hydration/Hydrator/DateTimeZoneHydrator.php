<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @implements ValueHydrator<\DateTimeZone>
 */
final class DateTimeZoneHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        return new \DateTimeZone((string) $input);
    }

    public function handles(): string
    {
        return \DateTimeZone::class;
    }
}
