<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Safe\DateTimeImmutable;

interface ClockInterface
{
    public function now(): DateTimeImmutable;
}
