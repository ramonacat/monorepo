<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\Event\Infrastructure\CommandExecutor\UpsertEventExecutor;
use Ramona\Ras2\Event\Infrastructure\EventIdDehydrator;
use Ramona\Ras2\Event\Infrastructure\EventIdHydrator;
use Ramona\Ras2\Event\Infrastructure\PostgresRepository;
use Ramona\Ras2\Event\Infrastructure\QueryExecutor\InMonthExecutor;
use Ramona\Ras2\Event\Infrastructure\Repository;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\CommandDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\QueryDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            Repository::class,
            fn ($c) => new PostgresRepository($c->get(Connection::class))
        );
    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(DefaultHydrator::class);
        $hydrator->installValueHydrator(new EventIdHydrator());
        $hydrator->installValueHydrator(new ObjectHydrator(EventView::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertEvent::class));
        $hydrator->installValueHydrator(new ObjectHydrator(InMonth::class));

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new EventIdDehydrator());
        $dehydrator->installValueDehydrator(new Dehydrator\ObjectDehydrator(EventView::class));

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(
            InMonth::class,
            new InMonthExecutor($container->get(Connection::class), $container->get(DefaultHydrator::class))
        );

        $commandBus = $container->get(CommandBus::class);
        $commandBus->installExecutor(
            UpsertEvent::class,
            new UpsertEventExecutor($container->get(Repository::class))
        );

        /** @var APIDefinition $apiDefinition */
        $apiDefinition = $container->get(APIDefinition::class);

        $apiDefinition->installQuery(
            new QueryDefinition('events', 'in-month', InMonth::class, ArrayCollection::class)
        );
        $apiDefinition->installCommand(new CommandDefinition('events', 'upsert', UpsertEvent::class));
    }
}
