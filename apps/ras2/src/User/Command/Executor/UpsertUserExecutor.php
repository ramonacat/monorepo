<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Command\Executor;

use Ramona\Ras2\CQRS\Command\Command;
use Ramona\Ras2\CQRS\Command\Executor;
use Ramona\Ras2\User\Command\UpsertUser;
use Ramona\Ras2\User\Repository;
use Ramona\Ras2\User\User;

/**
 * @implements Executor<UpsertUser>
 */
final class UpsertUserExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(Command $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $this->repository->save(new User($command->id, $command->name));
        });
    }
}
