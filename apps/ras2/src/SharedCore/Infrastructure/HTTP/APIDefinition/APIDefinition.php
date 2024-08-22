<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

final class APIDefinition
{
    /**
     * @var array<string, array<string, CommandDefinition>>
     */
    private array $commands = [];

    /**
     * @var array<string, array<string, QueryDefinition>>
     */
    private array $queries = [];

    /**
     * @var array<string, array<string, QueryCallbackDefinition>>
     */
    private array $queryCallbacks = [];

    /**
     * @var array<string, array<string, CommandCallbackDefinition>>
     */
    private mixed $commandCallbacks = [];

    public function installCommand(CommandDefinition $commandDefinition): void
    {
        $this->commands[$commandDefinition->path][$commandDefinition->actionName] = $commandDefinition;
    }

    public function installQuery(QueryDefinition $queryDefinition): void
    {
        $this->queries[$queryDefinition->path][$queryDefinition->queryName] = $queryDefinition;
    }

    public function installQueryCallback(QueryCallbackDefinition $queryCallbackDefinition): void
    {
        $this->queryCallbacks[$queryCallbackDefinition->path][$queryCallbackDefinition->queryName] = $queryCallbackDefinition;
    }

    public function installCommandCallback(CommandCallbackDefinition $commandCallbackDefinition): void
    {
        $this->commandCallbacks[$commandCallbackDefinition->path][$commandCallbackDefinition->commandName] = $commandCallbackDefinition;
    }

    /**
     * @return array<string, array<string, CommandDefinition>>
     */
    public function commands(): array
    {
        return $this->commands;
    }

    /**
     * @return array<string, array<string, QueryDefinition>>
     */
    public function queries(): array
    {
        return $this->queries;
    }

    /**
     * @return array<string, array<string, QueryCallbackDefinition>>
     */
    public function queryCallbacks(): array
    {
        return $this->queryCallbacks;
    }

    /**
     * @return array<string, array<string, CommandCallbackDefinition>>
     */
    public function commandCallbacks(): array
    {
        return $this->commandCallbacks;
    }
}
