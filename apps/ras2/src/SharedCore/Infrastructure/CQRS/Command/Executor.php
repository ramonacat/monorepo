<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command;

/**
 * @template TCommand of Command
 */
interface Executor
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     * @param TCommand $command
     */
    public function execute(Command $command): void;
}
