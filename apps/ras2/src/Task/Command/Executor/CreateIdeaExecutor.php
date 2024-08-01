<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command\Executor;

use Ramona\Ras2\Task\Command\CreateIdea;
use Ramona\Ras2\Task\Idea;
use Ramona\Ras2\Task\Repository;
use Ramona\Ras2\Task\TaskDescription;

/**
 * @implements Executor<CreateIdea>
 * @psalm-suppress UnusedClass
 */
final class CreateIdeaExecutor implements Executor
{
    private Repository $repository;

    public function __construct(Repository $repository)
    {
        $this->repository = $repository;
    }

    public function execute(object $command): void
    {
        $idea = new Idea(new TaskDescription($command->id, $command->categoryId, $command->title, $command->tags));
        $this
            ->repository
            ->save($idea);
    }
}
