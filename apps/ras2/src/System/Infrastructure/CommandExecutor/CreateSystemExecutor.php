<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\System\Application\Command\CreateSystem;
use Ramona\Ras2\System\Application\Command\SystemType;
use Ramona\Ras2\System\Business\NixOS;
use Ramona\Ras2\System\Business\System;
use Ramona\Ras2\System\Infrastructure\Repository;

/**
 * @implements Executor<CreateSystem>
 */
final class CreateSystemExecutor implements Executor
{
    public function __construct(
        private readonly Repository $repository,
        private readonly Hydrator $hydrator
    ) {
    }

    public function execute(Command $command): void
    {
        $operatingSystem = match ($command->type) {
            SystemType::NIXOS => $this->hydrator->hydrate(NixOS::class, $command->attributes->toArray()),
        };

        $system = new System($command->id, $command->hostname, $operatingSystem);

        $this->repository->insert($system);
    }
}
