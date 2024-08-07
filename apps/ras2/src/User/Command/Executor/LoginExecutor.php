<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Command\Executor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\User\Command\Login;
use Ramona\Ras2\User\Repository;

/**
 * @implements Executor<Login>
 */
final class LoginExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(Command $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $this->repository->assignTokenByUsername($command->username, $command->token);
        });
    }
}
