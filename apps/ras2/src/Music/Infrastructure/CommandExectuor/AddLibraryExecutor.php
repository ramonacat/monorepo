<?php

declare(strict_types=1);

namespace Ramona\Ras2\Music\Infrastructure\CommandExectuor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\Music\Application\Command\AddLibrary;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;

/**
 * @implements Executor<AddLibrary>
 */
final class AddLibraryExecutor implements Executor
{
    public function __construct(
        private Connection $connection
    ) {
    }

    public function execute(Command $command): void
    {
        $this->connection->executeStatement(
            'INSERT INTO music_libraries(id, path) VALUES(:id, :path)',
            [
                'id' => $command->id,
                'path' => $command->path,
            ]
        );
    }
}
