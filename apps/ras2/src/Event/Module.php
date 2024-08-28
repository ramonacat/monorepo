<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\Event\Infrastructure\PostgresRepository;
use Ramona\Ras2\Event\Infrastructure\Repository;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;

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
        /** @var APIDefinition $apiDefinition */
        $apiDefinition = $container->get(APIDefinition::class);

        $apiDefinition->installQuery(new QueryDefinition('events', 'in-month', InMonth::class));
        $apiDefinition->installCommand(new CommandDefinition('events', 'upsert', UpsertEvent::class));
    }
}
