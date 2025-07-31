<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use DateTimeZone;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @implements ValueHydrator<DateTimeZone>
 */
final class DateTimeZoneHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): DateTimeZone
    {
        return new DateTimeZone((string) $input);
    }

    /**
     * @return class-string<DateTimeZone>
     */
    public function handles(): string
    {
        return DateTimeZone::class;
    }
}
