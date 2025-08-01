<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use DateTimeImmutable;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @implements ValueDehydrator<DateTimeImmutable>
 */
final class DateTimeImmutableDehydrator implements ValueDehydrator
{
    /**
     * @return array{timestamp:string,timezone:string}
     */
    public function dehydrate(Dehydrator $dehydrator, mixed $value): array
    {
        $timezone = $value->getTimezone();

        return [
            'timestamp' => $value->format('Y-m-d H:i:s'),
            'timezone' => $timezone->getName(),
        ];
    }

    /**
     * @return class-string<DateTimeImmutable>
     */
    public function handles(): string
    {
        return DateTimeImmutable::class;
    }
}
