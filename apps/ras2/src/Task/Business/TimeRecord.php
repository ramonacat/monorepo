<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

final class TimeRecord
{
    public function __construct(
        private readonly \Safe\DateTimeImmutable $started,
        private ?\Safe\DateTimeImmutable $ended = null
    ) {
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function started(): \Safe\DateTimeImmutable
    {
        return $this->started;
    }

    public function ended(): ?\Safe\DateTimeImmutable
    {
        return $this->ended;
    }

    public function finish(\Safe\DateTimeImmutable $now): void
    {
        $this->ended = $now;
    }
}
