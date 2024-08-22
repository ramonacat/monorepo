<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command;

final class DefaultCommandBus implements CommandBus
{
    /**
     * @var array<class-string<Command>, Executor<Command>>
     */
    private $executors = [];

    public function installExecutor(string $type, object $handler): void
    {
        $this->executors[$type] = $handler;
    }

    public function execute(Command $command): void
    {
        $executor = $this->executors[get_class($command)] ?? throw NoExecutor::forCommand($command);

        $executor->execute($command);
    }
}
