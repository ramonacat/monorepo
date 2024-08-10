<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\DBAL\Connection;
use League\Route\Router;
use Ramona\Ras2\SharedCore\Infrastructure\ClockInterface;
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
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\HttpApi\GetTasks;
use Ramona\Ras2\Task\Application\HttpApi\PostTasks;
use Ramona\Ras2\Task\Application\HttpApi\StartWorkRequest;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Random;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\CreateIdeaExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\PauseWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\StartWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertBacklogItemExecutor;
use Ramona\Ras2\Task\Infrastructure\PostgresRepository;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\CurrentExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\CurrentTaskView;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\RandomExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\UpcomingExecutor;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\Task\Infrastructure\TaskIdDehydrator;
use Ramona\Ras2\Task\Infrastructure\TaskIdHydrator;
use Ramona\Ras2\Task\Infrastructure\TaskViewHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            Repository::class,
            fn (Container $c) => new PostgresRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class),
                $c->get(Deserializer::class),
            )
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
        $hydrator->installValueHydrator(new ObjectHydrator(StartWorkRequest::class));
        $hydrator->installValueHydrator(new ObjectHydrator(PauseWork::class));
        $hydrator->installValueHydrator(new ObjectHydrator(TimeRecord::class));
        $hydrator->installValueHydrator(new TaskViewHydrator());
        $hydrator->installValueHydrator(new TaskIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TaskView::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TimeRecord::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(CurrentTaskView::class));
        $dehydrator->installValueDehydrator(new TaskIdDehydrator());

        $commandBus = $container->get(CommandBus::class);

        $commandBus->installExecutor(UpsertIdea::class, new CreateIdeaExecutor($container->get(Repository::class)));
        $commandBus->installExecutor(
            UpsertBacklogItem::class,
            new UpsertBacklogItemExecutor($container->get(Repository::class))
        );
        $commandBus->installExecutor(
            StartWork::class,
            new StartWorkExecutor($container->get(Repository::class), $container->get(ClockInterface::class))
        );
        $commandBus->installExecutor(
            PauseWork::class,
            new PauseWorkExecutor($container->get(Repository::class), $container->get(ClockInterface::class))
        );

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(
            Upcoming::class,
            new UpcomingExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );
        $queryBus->installExecutor(
            Random::class,
            new RandomExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );
        $queryBus->installExecutor(Current::class, new CurrentExecutor($container->get(Connection::class)));

        $router = $container->get(Router::class);
        $router->map('GET', '/tasks', GetTasks::class);
        $router->map('POST', '/tasks', PostTasks::class);
    }
}