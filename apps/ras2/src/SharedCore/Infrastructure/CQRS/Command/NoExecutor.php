<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command;

use RuntimeException;

final class NoExecutor extends RuntimeException
{
    public static function forCommand(Command $command): self
    {
        $commandClass = get_class($command);
        return new self("Could not find an executor for a command of type '{$commandClass}'");
    }
}
