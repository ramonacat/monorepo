<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command\Executor;

use Ramona\Ras2\Task\Command\Command;

/**
 * @template TCommand of Command
 */
interface Executor
{
    /**
     * @param TCommand $command
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function execute(Command $command): void;
}
