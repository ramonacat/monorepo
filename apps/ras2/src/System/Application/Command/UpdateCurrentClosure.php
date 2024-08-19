<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;

final class UpdateCurrentClosure implements Command
{
    public function __construct(
        public string $hostname,
        public string $currentClosure
    ) {
    }
}
