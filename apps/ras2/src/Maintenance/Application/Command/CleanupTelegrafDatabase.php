<?php

declare(strict_types=1);

namespace Ramona\Ras2\Maintenance\Application\Command;

use Ramona\Ras2\Maintenance\Infrastructure\CommandExecutor\CleanupTelegrafDatabaseExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;

#[ExecutedBy(CleanupTelegrafDatabaseExecutor::class), APICommand('maintenance', 'cleanup-telegraf-database')]
final class CleanupTelegrafDatabase implements Command
{
}
