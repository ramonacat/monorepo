<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\System\Infrastructure\CommandExecutor\UpdateCurrentClosureExecutor;

#[ExecutedBy(UpdateCurrentClosureExecutor::class)]
final class UpdateCurrentClosure implements Command
{
    public function __construct(
        public string $hostname,
        public string $currentClosure
    ) {
    }
}
