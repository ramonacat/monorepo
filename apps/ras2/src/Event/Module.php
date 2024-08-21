<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use Doctrine\DBAL\Connection;
use League\Route\Router;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\Event\Application\HttpApi\GetEvents;
use Ramona\Ras2\Event\Application\HttpApi\PostEvents;
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
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\QueryExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(GetEvents::class, fn ($c) => new GetEvents($c->get(QueryExecutor::class)));
        $containerBuilder->register(PostEvents::class, fn ($c) => new PostEvents($c->get(CommandExecutor::class)));
        $containerBuilder->register(
            Repository::class,
            fn ($c) => new PostgresRepository($c->get(Connection::class))
        );
    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(Hydrator::class);
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
            new InMonthExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );

        $commandBus = $container->get(CommandBus::class);
        $commandBus->installExecutor(
            UpsertEvent::class,
            new UpsertEventExecutor($container->get(Repository::class))
        );

        $router = $container->get(Router::class);
        $router->map('GET', '/events', GetEvents::class);
        $router->map('POST', '/events', PostEvents::class);
    }
}
