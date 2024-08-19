<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Business;

final class NixOS implements OperatingSystem
{
    public function __construct(
        /**
         * @phpstan-ignore property.onlyWritten
         */
        private string $currentClosure,
        /**
         * @phpstan-ignore property.onlyWritten
         */
        private ?string $latestClosure
    ) {
    }

    public function updateCurrentClosure(string $currentClosure): void
    {
        $this->currentClosure = $currentClosure;
    }

    public function updateLatestClosure(string $latestClosure): void
    {
        $this->latestClosure = $latestClosure;
    }
}
