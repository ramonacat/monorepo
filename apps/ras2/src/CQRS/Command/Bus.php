<?php

declare(strict_types=1);

namespace Ramona\Ras2\CQRS\Command;

/**
 * @psalm-suppress UnusedClass
 */
final class Bus
{
    /**
     * @var array<class-string, Executor<Command>>
     */
    private $executors = [];

    /**
     * @template TCommand of Command
     * @template TCommandExecutor of Executor<TCommand>
     * @param class-string<TCommand> $type
     * @param TCommandExecutor $handler
     */
    public function installExecutor(string $type, object $handler): void
    {
        $this->executors[$type] = $handler;
    }

    public function execute(Command $command): void
    {
        $executor = $this->executors[get_class($command)];
        $executor->execute($command);
    }
}
