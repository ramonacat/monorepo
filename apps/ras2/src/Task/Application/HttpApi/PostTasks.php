<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\ReturnToBacklog;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;

final readonly class PostTasks
{
    public function __construct(
        private CommandExecutor $commandExecutor
    ) {
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        return $this->commandExecutor->execute($request, [
            'upsert:idea' => UpsertIdea::class,
            'upsert:backlog-item' => UpsertBacklogItem::class,
            'start-work' => StartWork::class,
            'pause-work' => PauseWork::class,
            'finish-work' => FinishWork::class,
            'return-to-backlog' => ReturnToBacklog::class,
        ]);
    }
}
