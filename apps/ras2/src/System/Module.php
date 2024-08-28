<?php

declare(strict_types=1);

namespace Ramona\Ras2\System;

use DI\ContainerBuilder;
use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\System\Infrastructure\PostgresRepository;
use Ramona\Ras2\System\Infrastructure\Repository;
use Ramona\Ras2\System\Infrastructure\SystemHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->addDefinitions([
            Repository::class => fn (ContainerInterface $c) => new PostgresRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class),
                $c->get(Hydrator::class)
            ),
        ]);
    }

    public function register(ContainerInterface $container): void
    {
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new SystemHydrator());
    }
}
