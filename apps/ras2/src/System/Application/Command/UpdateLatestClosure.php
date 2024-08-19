<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;

final readonly class UpdateLatestClosure implements Command
{
    public function __construct(
        public string $hostname,
        public string $latestClosure
    ) {
    }
}
