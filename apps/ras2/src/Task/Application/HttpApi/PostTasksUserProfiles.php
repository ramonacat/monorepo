<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;
use Ramona\Ras2\Task\Application\Command\UpsertUserProfile;

final class PostTasksUserProfiles
{
    public function __construct(
        private CommandExecutor $commandExecutor
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        return $this->commandExecutor->execute($request, [
            'upsert' => UpsertUserProfile::class,
        ]);
    }
}
