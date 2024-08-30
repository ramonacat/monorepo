<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\Task\Application\Command\CreateFilter;
use Ramona\Ras2\Task\Business\Filter;
use Ramona\Ras2\Task\Business\FilterId;
use Ramona\Ras2\Task\Infrastructure\FilterRepository;
use Ramona\Ras2\Task\Infrastructure\Repository;

/**
 * @implements Executor<CreateFilter>
 */
final readonly class CreateFilterExecutor implements Executor
{
    public function __construct(
        private Repository $taskRepository,
        private FilterRepository $filterRepository
    ) {
    }

    public function execute(Command $command): void
    {
        $tags = $this->taskRepository->fetchOrCreateTags($command->tags);

        $this->filterRepository->upsert(new Filter(
            FilterId::generate(),
            $command->name,
            $command->assignees,
            $tags
        ));
    }
}
