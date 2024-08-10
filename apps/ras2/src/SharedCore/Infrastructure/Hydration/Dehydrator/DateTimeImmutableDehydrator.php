<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @implements ValueDehydrator<\DateTimeImmutable>
 */
final class DateTimeImmutableDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        $timezone = $value->getTimezone();

        return [
            'timestamp' => $value->getTimestamp(),
            'timezone' => $timezone->getName(),
        ];
    }

    public function handles(): string
    {
        return \DateTimeImmutable::class;
    }
}
