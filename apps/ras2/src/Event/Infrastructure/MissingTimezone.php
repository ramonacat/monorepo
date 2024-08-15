<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Infrastructure;

final class MissingTimezone extends \RuntimeException
{
    public static function forDate(\DateTimeImmutable $start): self
    {
        $formatted = $start->format('Y-m-d H:i:s');
        return new self("The date {$formatted} does not have a timezone");
    }
}
