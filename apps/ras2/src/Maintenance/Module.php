<?php

declare(strict_types=1);

namespace Ramona\Ras2\Maintenance;

use DI\ContainerBuilder;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\Maintenance\Infrastructure\CommandExecutor\CleanupTelegrafDatabaseExecutor;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->addDefinitions([
            CleanupTelegrafDatabaseExecutor::class => fn (ContainerInterface $container) => new CleanupTelegrafDatabaseExecutor(
                $container->get('db.telegraf')
            ),
        ]);
    }

    public function register(ContainerInterface $container): void
    {
    }
}
