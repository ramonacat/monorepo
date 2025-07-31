<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Business;

use DateTimeZone;
use Safe\DateTimeImmutable;

final class System
{
    public function __construct(
        private SystemId $id,
        private string $hostname,
        private OperatingSystem $operatingSystem,
        private ?DateTimeImmutable $latestPing,
    ) {
    }

    public function refreshPingDateTime(DateTimeImmutable $now): void
    {
        $this->latestPing = $now->setTimezone(new DateTimeZone('UTC'));
    }

    public function id(): SystemId
    {
        return $this->id;
    }

    public function hostname(): string
    {
        return $this->hostname;
    }

    public function operatingSystem(): OperatingSystem
    {
        return $this->operatingSystem;
    }

    public function latestPing(): ?\DateTimeImmutable
    {
        return $this->latestPing;
    }
}
