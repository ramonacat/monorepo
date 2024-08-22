<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command;

interface CommandBus
{
    public function execute(Command $command): void;

    /**
     * @template TCommand of Command
     * @param class-string<TCommand> $type
     * @param Executor<TCommand> $handler
     */
    public function installExecutor(string $type, object $handler): void;
}
