<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Psr\Container\ContainerInterface;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\Event\Infrastructure\EventIdDehydrator;
use Ramona\Ras2\Event\Infrastructure\EventIdHydrator;
use Ramona\Ras2\Event\Infrastructure\PostgresRepository;
use Ramona\Ras2\Event\Infrastructure\Repository;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

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
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new EventIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new EventIdDehydrator());

        /** @var APIDefinition $apiDefinition */
        $apiDefinition = $container->get(APIDefinition::class);

        $apiDefinition->installQuery(
            new QueryDefinition('events', 'in-month', InMonth::class, ArrayCollection::class)
        );
        $apiDefinition->installCommand(new CommandDefinition('events', 'upsert', UpsertEvent::class));
    }
}
