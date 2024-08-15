<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use Doctrine\DBAL\Connection;
use League\Route\Router;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\Event\Application\HttpApi\GetEvents;
use Ramona\Ras2\Event\Application\Query\InMonth;
use Ramona\Ras2\Event\Infrastructure\EventIdDehydrator;
use Ramona\Ras2\Event\Infrastructure\EventIdHydrator;
use Ramona\Ras2\Event\Infrastructure\QueryExecutor\InMonthExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            GetEvents::class,
            fn ($c) => new GetEvents($c->get(QueryBus::class), $c->get(JsonResponseFactory::class))
        );
    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new EventIdHydrator());
        $hydrator->installValueHydrator(new ObjectHydrator(EventView::class));

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new EventIdDehydrator());
        $dehydrator->installValueDehydrator(new Dehydrator\ObjectDehydrator(EventView::class));

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(
            InMonth::class,
            new InMonthExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );

        $router = $container->get(Router::class);
        $router->map('GET', '/events', GetEvents::class);
    }
}
