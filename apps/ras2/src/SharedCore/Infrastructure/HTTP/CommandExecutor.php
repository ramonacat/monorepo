<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;

interface CommandExecutor
{
    /**
     * @param array<string, class-string<Command>> $actionToCommandType
     */
    public function execute(ServerRequestInterface $request, array $actionToCommandType): ResponseInterface;
}
