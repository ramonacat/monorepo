<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use DateTimeZone;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @implements ValueHydrator<\Safe\DateTimeImmutable>
 */
final class DateTimeImmutableHydrator implements ValueHydrator
{
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): \Safe\DateTimeImmutable
    {
        $timezone = new DateTimeZone((string) $input['timezone']);

        return \Safe\DateTimeImmutable::createFromFormat('Y-m-d H:i:s', (string) $input['timestamp'], $timezone);
    }

    /**
     * @return class-string<\Safe\DateTimeImmutable>
     */
    public function handles(): string
    {
        return \Safe\DateTimeImmutable::class;
    }
}
