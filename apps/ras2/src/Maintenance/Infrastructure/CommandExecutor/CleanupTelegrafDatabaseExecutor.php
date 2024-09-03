<?php

declare(strict_types=1);

namespace Ramona\Ras2\Maintenance\Infrastructure\CommandExecutor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\Maintenance\Application\Command\CleanupTelegrafDatabase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Executor;

/**
 * @implements Executor<CleanupTelegrafDatabase>
 */
final readonly class CleanupTelegrafDatabaseExecutor implements Executor
{
    public function __construct(
        private Connection $telegrafConnection
    ) {
    }

    public function execute(Command $command): void
    {
        $tables = $this->telegrafConnection->fetchFirstColumn(
            'SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = \'public\''
        );
        foreach ($tables as $table) {
            $this->telegrafConnection->executeStatement(
                "DELETE FROM {$table} WHERE time < (NOW() - \'30 days\'::interval)"
            );
        }
    }
}
