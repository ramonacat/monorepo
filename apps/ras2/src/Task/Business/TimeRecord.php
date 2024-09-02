<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Safe\DateTimeImmutable;

final class TimeRecord
{
    public function __construct(
        private readonly DateTimeImmutable $started,
        private ?DateTimeImmutable $ended = null
    ) {
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function started(): DateTimeImmutable
    {
        return $this->started;
    }

    public function ended(): ?DateTimeImmutable
    {
        return $this->ended;
    }

    public function finish(DateTimeImmutable $now): void
    {
        $this->ended = $now;
    }

    public function isFinished(): bool
    {
        return $this->ended !== null;
    }
}
