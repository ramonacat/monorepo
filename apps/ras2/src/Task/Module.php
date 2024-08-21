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
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\QueryExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ObjectDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Application\Command\PauseWork;
use Ramona\Ras2\Task\Application\Command\ReturnToBacklog;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Application\Command\UpsertIdea;
use Ramona\Ras2\Task\Application\Command\UpsertUserProfile;
use Ramona\Ras2\Task\Application\CurrentTaskView;
use Ramona\Ras2\Task\Application\HttpApi\GetTaskById;
use Ramona\Ras2\Task\Application\HttpApi\GetTasks;
use Ramona\Ras2\Task\Application\HttpApi\GetTasksUserProfiles;
use Ramona\Ras2\Task\Application\HttpApi\PostTasks;
use Ramona\Ras2\Task\Application\HttpApi\PostTasksUserProfiles;
use Ramona\Ras2\Task\Application\Query\ById;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\Query\UserProfileByUserId;
use Ramona\Ras2\Task\Application\Query\WatchedBy;
use Ramona\Ras2\Task\Application\TagView;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Application\UserProfileView;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\CreateIdeaExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\FinishWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\PauseWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\ReturnToBacklogExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\StartWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertBacklogItemExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertUserProfileExecutor;
use Ramona\Ras2\Task\Infrastructure\PostgresRepository;
use Ramona\Ras2\Task\Infrastructure\PostgresUserProfileRepository;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\ByIdExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\CurrentExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\UpcomingExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\UserProfileByUserIdExecutor;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\WatchedByExecutor;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\Task\Infrastructure\TagIdDehydrator;
use Ramona\Ras2\Task\Infrastructure\TagIdHydrator;
use Ramona\Ras2\Task\Infrastructure\TaskIdDehydrator;
use Ramona\Ras2\Task\Infrastructure\TaskIdHydrator;
use Ramona\Ras2\Task\Infrastructure\UserProfileRepository;

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
            fn (Container $c) => new GetTasks($c->get(QueryExecutor::class))
        );
        $containerBuilder->register(
            GetTaskById::class,
            fn (Container $c) => new GetTaskById($c->get(QueryExecutor::class))
        );
        $containerBuilder->register(
            PostTasks::class,
            fn (Container $c) => new PostTasks($c->get(CommandExecutor::class))
        );
        $containerBuilder->register(
            PostTasksUserProfiles::class,
            fn (Container $c) => new PostTasksUserProfiles($c->get(CommandExecutor::class))
        );
        $containerBuilder->register(
            UserProfileRepository::class,
            fn (Container $c) => new PostgresUserProfileRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class)
            )
        );

        $containerBuilder->register(
            GetTasksUserProfiles::class,
            fn (Container $c) => new GetTasksUserProfiles($c->get(QueryExecutor::class))
        );
    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertBacklogItem::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertIdea::class));
        $hydrator->installValueHydrator(new ObjectHydrator(PauseWork::class));
        $hydrator->installValueHydrator(new ObjectHydrator(TimeRecord::class));
        $hydrator->installValueHydrator(new ObjectHydrator(FinishWork::class));
        $hydrator->installValueHydrator(new ObjectHydrator(StartWork::class));
        $hydrator->installValueHydrator(new ObjectHydrator(ReturnToBacklog::class));
        $hydrator->installValueHydrator(new ObjectHydrator(TaskView::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpsertUserProfile::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UserProfileView::class));
        $hydrator->installValueHydrator(new ObjectHydrator(TagView::class));
        $hydrator->installValueHydrator(new ObjectHydrator(WatchedBy::class));
        $hydrator->installValueHydrator(new ObjectHydrator(Upcoming::class));
        $hydrator->installValueHydrator(new ObjectHydrator(Current::class));
        $hydrator->installValueHydrator(new TaskIdHydrator());
        $hydrator->installValueHydrator(new TagIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TaskView::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TimeRecord::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(CurrentTaskView::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(UserProfileView::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(TagView::class));
        $dehydrator->installValueDehydrator(new TaskIdDehydrator());
        $dehydrator->installValueDehydrator(new TagIdDehydrator());

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
        $commandBus->installExecutor(
            FinishWork::class,
            new FinishWorkExecutor($container->get(Repository::class), $container->get(ClockInterface::class))
        );
        $commandBus->installExecutor(
            ReturnToBacklog::class,
            new ReturnToBacklogExecutor($container->get(Repository::class), $container->get(ClockInterface::class))
        );
        $commandBus->installExecutor(
            UpsertUserProfile::class,
            new UpsertUserProfileExecutor(
                $container->get(UserProfileRepository::class),
                $container->get(Repository::class)
            )
        );

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(
            Upcoming::class,
            new UpcomingExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );
        $queryBus->installExecutor(
            WatchedBy::class,
            new WatchedByExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );
        $queryBus->installExecutor(Current::class, new CurrentExecutor($container->get(Connection::class)));
        $queryBus->installExecutor(
            ById::class,
            new ByIdExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );
        $queryBus->installExecutor(
            UserProfileByUserId::class,
            new UserProfileByUserIdExecutor($container->get(Connection::class), $container->get(Hydrator::class))
        );

        $router = $container->get(Router::class);
        $router->map('GET', '/tasks', GetTasks::class);
        $router->map('GET', '/tasks/{id:uuid}', GetTaskById::class);
        $router->map('POST', '/tasks', PostTasks::class);
        $router->map('POST', '/tasks/user-profiles', PostTasksUserProfiles::class);
        $router->map('GET', '/tasks/user-profiles', GetTasksUserProfiles::class);
    }
}
