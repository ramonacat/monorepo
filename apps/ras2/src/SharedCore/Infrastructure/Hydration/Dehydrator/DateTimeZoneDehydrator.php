<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use DateTimeZone;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @implements ValueDehydrator<\DateTimeZone>
 */
final class DateTimeZoneDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): string
    {
        return $value->getName();
    }

    /**
     * @return class-string<DateTimeZone>
     */
    public function handles(): string
    {
        return DateTimeZone::class;
    }
}
