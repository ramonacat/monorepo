<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure\CommandExecutor;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;
use Ramona\Ras2\System\Application\Command\UpdateLatestClosure;
use Ramona\Ras2\System\Business\NixOS;
use Ramona\Ras2\System\Infrastructure\Repository;
use RuntimeException;

/**
 * @implements Executor<UpdateLatestClosure>
 */
final class UpdateLatestClosureExecutor implements Executor
{
    public function __construct(
        private Repository $repository
    ) {
    }

    public function execute(Command $command): void
    {
        $system = $this->repository->getByHostname($command->hostname);
        $operatingSystem = $system->operatingSystem();

        if (! ($operatingSystem instanceof NixOS)) {
            throw new RuntimeException('Unexpected operating system: ' . get_class($operatingSystem));
        }
        $operatingSystem->updateLatestClosure($command->latestClosure);

        $this->repository->save($system);
    }
}
