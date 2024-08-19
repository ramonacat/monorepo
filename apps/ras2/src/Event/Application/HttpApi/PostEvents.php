<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;

final readonly class PostEvents
{
    public function __construct(
        private CommandExecutor $commandExecutor
    ) {

    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        return $this->commandExecutor->execute($request, [
            'upsert' => UpsertEvent::class,
        ]);
    }
}
