<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\User\Application\Command\UpsertUser;
use Ramona\Ras2\User\Business\User;
use Ramona\Ras2\User\Infrastructure\Repository;

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
