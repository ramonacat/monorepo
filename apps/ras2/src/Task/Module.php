<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\DBAL\Connection;
use League\Route\Router;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus as CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ObjectDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\HttpApi\GetTasks;
use Ramona\Ras2\Task\Application\HttpApi\PostTasks;
use Ramona\Ras2\Task\Application\Query\FindRandom;
use Ramona\Ras2\Task\Application\Query\FindUpcoming;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\CreateIdeaExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertBacklogItemExecutor;
use Ramona\Ras2\Task\Infrastructure\PostgresRepository;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\FindRandomExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\FindUpcomingExecutor;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\Task\Infrastructure\TaskIdDehydrator;
use Ramona\Ras2\Task\Infrastructure\TaskIdHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            Repository::class,
            fn (Container $c) => new PostgresRepository($c->get(Connection::class))
        );

        $containerBuilder->register(
            GetTasks::class,
            fn (Container $c) => new GetTasks($c->get(QueryBus::class), $c->get(Serializer::class))
        );
        $containerBuilder->register(
            PostTasks::class,
            fn (Container $c) => new PostTasks($c->get(CommandBus::class), $c->get(Deserializer::class))
        );
    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertBacklogItem::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertIdea::class));
        $hydrator->installValueHydrator(new TaskIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TaskView::class));
        $dehydrator->installValueDehydrator(new TaskIdDehydrator());

        $commandBus = $container->get(CommandBus::class);

        $commandBus->installExecutor(UpsertIdea::class, new CreateIdeaExecutor($container->get(Repository::class)));
        $commandBus->installExecutor(
            UpsertBacklogItem::class,
            new UpsertBacklogItemExecutor($container->get(Repository::class))
        );

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(FindUpcoming::class, new FindUpcomingExecutor($container->get(Connection::class)));
        $queryBus->installExecutor(FindRandom::class, new FindRandomExecutor($container->get(Connection::class)));

        $router = $container->get(Router::class);
        $router->map('GET', '/tasks', GetTasks::class);
        $router->map('POST', '/tasks', PostTasks::class);
    }
}
