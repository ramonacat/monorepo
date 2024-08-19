<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Business;

final class System
{
    public function __construct(
        private SystemId $id,
        private string $hostname,
        private OperatingSystem $operatingSystem
    ) {
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
}
