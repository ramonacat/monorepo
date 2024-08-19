<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;
use Ramona\Ras2\System\Application\Command\CreateSystem;
use Ramona\Ras2\System\Application\Command\UpdateCurrentClosure;
use Ramona\Ras2\System\Application\Command\UpdateLatestClosure;

final readonly class PostSystem
{
    public function __construct(
        private CommandExecutor $commandExecutor,
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        return $this->commandExecutor->execute($request, [
            'create' => CreateSystem::class,
            'update-current-closure' => UpdateCurrentClosure::class,
            'update-latest-closure' => UpdateLatestClosure::class,
        ]);
    }
}
