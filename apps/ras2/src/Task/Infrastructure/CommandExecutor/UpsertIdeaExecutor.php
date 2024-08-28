<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Business\Idea;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<UpsertIdea>
 * @psalm-suppress UnusedClass
 */
final readonly class UpsertIdeaExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(object $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $tags = $this->repository->fetchOrCreateTags($command->tags);
            $idea = new Idea(new TaskDescription($command->id, $command->title, $tags));
            $this
                ->repository
                ->save($idea);
        });
    }
}
