<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\CQRS\Command\Executor;
use Ramona\Ras2\Task\Command\CreateIdea;
use Ramona\Ras2\Task\Idea;
use Ramona\Ras2\Task\Repository;
use Ramona\Ras2\Task\TaskDescription;

/**
 * @implements Executor<CreateIdea>
 * @psalm-suppress UnusedClass
 */
final readonly class CreateIdeaExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(object $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $tags = $this->repository->fetchOrCreateTags($command->tags->toArray());
            $idea = new Idea(new TaskDescription($command->id, $command->title, new ArrayCollection($tags)));
            $this
                ->repository
                ->save($idea);
        });
    }
}
