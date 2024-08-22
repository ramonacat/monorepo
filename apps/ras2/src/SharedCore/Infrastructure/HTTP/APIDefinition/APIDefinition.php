<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

final class APIDefinition
{
    /**
     * @var array<string, array<string, class-string<Command>>>
     */
    private array $commands = [];

    /**
     * @var array<string, array<string, class-string<Query<mixed>>>>
     */
    private array $queries = [];

    /**
     * @var array<string, array<string, callable(ServerRequestInterface):mixed>>
     */
    private array $queryCallbacks = [];

    /**
     * @var array<string, array<string, callable(ServerRequestInterface):?mixed>>
     */
    private mixed $commandCallbacks = [];

    /**
     * @param class-string<Command> $commandDefinition
     */
    public function installCommand(string $path, string $actionName, string $commandDefinition): void
    {
        $this->commands[$path][$actionName] = $commandDefinition;
    }

    /**
     * @param class-string<Query<mixed>> $queryDefinition
     */
    public function installQuery(string $path, string $queryName, string $queryDefinition): void
    {
        $this->queries[$path][$queryName] = $queryDefinition;
    }

    /**
     * @param callable(ServerRequestInterface):mixed $callback
     */
    public function installQueryCallback(string $path, string $queryName, callable $callback): void
    {
        $this->queryCallbacks[$path][$queryName] = $callback;
    }

    /**
     * @param callable(ServerRequestInterface):?mixed $callback
     */
    public function installCommandCallback(string $path, string $commandName, callable $callback): void
    {
        $this->commandCallbacks[$path][$commandName] = $callback;
    }

    /**
     * @return array<string, array<string, class-string<Command>>>
     */
    public function commands(): array
    {
        return $this->commands;
    }

    /**
     * @return array<string, array<string, class-string<Query<mixed>>>>
     */
    public function queries(): array
    {
        return $this->queries;
    }

    /**
     * @return array<string, array<string, callable(ServerRequestInterface):mixed>>
     */
    public function queryCallbacks(): array
    {
        return $this->queryCallbacks;
    }

    /**
     * @return array<string, array<string, callable(ServerRequestInterface):?mixed>>
     */
    public function commandCallbacks(): array
    {
        return $this->commandCallbacks;
    }
}
