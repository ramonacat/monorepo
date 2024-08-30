<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use DI\ContainerBuilder;
use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Infrastructure\FilterRepository;
use Ramona\Ras2\Task\Infrastructure\PostgresFilterRepository;
use Ramona\Ras2\Task\Infrastructure\PostgresRepository;
use Ramona\Ras2\Task\Infrastructure\PostgresUserProfileRepository;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\Task\Infrastructure\UserProfileRepository;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->addDefinitions([
            Repository::class => fn (ContainerInterface $c) => new PostgresRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class),
                $c->get(Deserializer::class)
            ),
            UserProfileRepository::class => fn (ContainerInterface $c) => new PostgresUserProfileRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class)
            ),
            FilterRepository::class => fn (ContainerInterface $c) => new PostgresFilterRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class)
            ),
        ]);
    }

    public function register(ContainerInterface $container): void
    {
    }
}
