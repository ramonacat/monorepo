<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\System\Application\Command\UpdateCurrentClosure;
use Ramona\Ras2\System\Business\NixOS;
use Ramona\Ras2\System\Infrastructure\Repository;
use RuntimeException;
use Safe\DateTimeImmutable;

/**
 * @implements Executor<UpdateCurrentClosure>
 */
final class UpdateCurrentClosureExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(Command $command): void
    {
        $this->repository->transactional(function () use ($command) {
            $system = $this->repository->getByHostname($command->hostname);
            $now = new DateTimeImmutable();
            $system->refreshPingDateTime($now);
            $operatingSystem = $system->operatingSystem();
            if (! ($operatingSystem instanceof NixOS)) {
                throw new RuntimeException('Closures can only be set for NixOS systems');
            }
            $operatingSystem->updateCurrentClosure($command->currentClosure);

            $this->repository->save($system);
        });
    }
}
