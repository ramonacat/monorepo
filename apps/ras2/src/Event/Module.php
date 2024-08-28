<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\Event\Infrastructure\PostgresRepository;
use Ramona\Ras2\Event\Infrastructure\Repository;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(\DI\ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->addDefinitions([
            Repository::class => fn (ContainerInterface $c) => new PostgresRepository($c->get(Connection::class)),
        ]);
    }

    public function register(ContainerInterface $container): void
    {
    }
}
