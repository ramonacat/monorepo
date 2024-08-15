<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

use Doctrine\DBAL\Connection;
use League\Route\Router;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ObjectDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\User\Application\Command\Login;
use Ramona\Ras2\User\Application\Command\LoginRequest;
use Ramona\Ras2\User\Application\Command\LoginResponse;
use Ramona\Ras2\User\Application\Command\UpsertUser;
use Ramona\Ras2\User\Application\HttpApi\GetUsers;
use Ramona\Ras2\User\Application\HttpApi\PostUsers;
use Ramona\Ras2\User\Application\Query\FindByToken;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Infrastructure\CommandExecutor\LoginExecutor;
use Ramona\Ras2\User\Infrastructure\CommandExecutor\UpsertUserExecutor;
use Ramona\Ras2\User\Infrastructure\PostgresRepository;
use Ramona\Ras2\User\Infrastructure\QueryExecutor\FindByTokenExecutor;
use Ramona\Ras2\User\Infrastructure\Repository;
use Ramona\Ras2\User\Infrastructure\TokenDehydrator;
use Ramona\Ras2\User\Infrastructure\UserIdDehydrator;
use Ramona\Ras2\User\Infrastructure\UserIdHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            Repository::class,
            fn (Container $c) => new PostgresRepository($c->get(Connection::class))
        );
        $containerBuilder->register(
            GetUsers::class,
            fn (Container $container) => new GetUsers($container->get(JsonResponseFactory::class))
        );
        $containerBuilder->register(
            PostUsers::class,
            fn (Container $container) => new PostUsers($container->get(CommandBus::class), $container->get(
                Serializer::class
            ), $container->get(Deserializer::class))
        );

    }

    public function register(Container $container): void
    {
        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new ObjectHydrator(LoginRequest::class));
        $hydrator->installValueHydrator(new UserIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new UserIdDehydrator());
        $dehydrator->installValueDehydrator(new ObjectDehydrator(LoginResponse::class));
        $dehydrator->installValueDehydrator(new ObjectDehydrator(Session::class));
        $dehydrator->installValueDehydrator(new TokenDehydrator());

        $commandBus = $container->get(CommandBus::class);
        $commandBus->installExecutor(UpsertUser::class, new UpsertUserExecutor($container->get(Repository::class)));
        $commandBus->installExecutor(Login::class, new LoginExecutor($container->get(Repository::class)));

        $queryBus = $container->get(QueryBus::class);
        $queryBus->installExecutor(FindByToken::class, new FindByTokenExecutor($container->get(Connection::class)));

        $router = $container->get(Router::class);
        $router->map('GET', '/users', GetUsers::class);
        $router->map('POST', '/users', PostUsers::class);
    }
}
