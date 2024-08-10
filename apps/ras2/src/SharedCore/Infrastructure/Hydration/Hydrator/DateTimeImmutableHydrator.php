<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueHydrator;

/**
 * @implements ValueHydrator<\Safe\DateTimeImmutable>
 */
final class DateTimeImmutableHydrator implements ValueHydrator
{
    /**
     * @psalm-suppress MixedArrayAccess
     * @psalm-suppress ArgumentTypeCoercion
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed
    {
        $timezone = new \DateTimeZone((string) $input['timezone']);

        return \Safe\DateTimeImmutable::createFromFormat('U', (string) $input['timestamp'], $timezone);
    }

    public function handles(): string
    {
        return \Safe\DateTimeImmutable::class;
    }
}
