<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Safe\DateTimeImmutable;

final class SystemClock implements Clock
{
    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable();
    }
}
