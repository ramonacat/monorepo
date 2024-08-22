<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;

final class CommandDefinition
{
    /**
     * @param class-string<Command> $commandType
     */
    public function __construct(
        public string $path,
        public string $actionName,
        public string $commandType
    ) {
    }
}
