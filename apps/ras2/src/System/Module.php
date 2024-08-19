<?php

declare(strict_types=1);

namespace Ramona\Ras2\System;

use Doctrine\DBAL\Connection;
use League\Route\Router;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\DefaultCommandExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\EnumHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ObjectHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\System\Application\Command\CreateSystem;
use Ramona\Ras2\System\Application\Command\SystemType;
use Ramona\Ras2\System\Application\Command\UpdateCurrentClosure;
use Ramona\Ras2\System\Application\Command\UpdateLatestClosure;
use Ramona\Ras2\System\Application\HttpApi\PostSystem;
use Ramona\Ras2\System\Business\NixOS;
use Ramona\Ras2\System\Infrastructure\CommandExecutor\CreateSystemExecutor;
use Ramona\Ras2\System\Infrastructure\CommandExecutor\UpdateCurrentClosureExecutor;
use Ramona\Ras2\System\Infrastructure\CommandExecutor\UpdateLatestClosureExecutor;
use Ramona\Ras2\System\Infrastructure\PostgresRepository;
use Ramona\Ras2\System\Infrastructure\Repository;
use Ramona\Ras2\System\Infrastructure\SystemHydrator;
use Ramona\Ras2\System\Infrastructure\SystemIdHydrator;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(
            PostSystem::class,
            fn ($c) => new PostSystem($c->get(DefaultCommandExecutor::class))
        );

        $containerBuilder->register(
            Repository::class,
            fn ($c) => new PostgresRepository(
                $c->get(Connection::class),
                $c->get(Serializer::class),
                $c->get(Hydrator::class)
            )
        );
    }

    public function register(Container $container): void
    {
        /** @var Router $router */
        $router = $container->get(Router::class);
        $router->post('systems', PostSystem::class);

        $hydrator = $container->get(Hydrator::class);
        $hydrator->installValueHydrator(new ObjectHydrator(CreateSystem::class));
        $hydrator->installValueHydrator(new ObjectHydrator(NixOS::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpdateCurrentClosure::class));
        $hydrator->installValueHydrator(new ObjectHydrator(UpdateLatestClosure::class));
        $hydrator->installValueHydrator(new SystemHydrator());
        $hydrator->installValueHydrator(new EnumHydrator(SystemType::class));
        $hydrator->installValueHydrator(new SystemIdHydrator());

        $dehydrator = $container->get(Dehydrator::class);
        $dehydrator->installValueDehydrator(new Dehydrator\ObjectDehydrator(NixOS::class));

        $commandBus = $container->get(CommandBus::class);
        $commandBus->installExecutor(CreateSystem::class, new CreateSystemExecutor(
            $container->get(Repository::class),
            $container->get(Hydrator::class)
        ));
        $commandBus->installExecutor(
            UpdateCurrentClosure::class,
            new UpdateCurrentClosureExecutor($container->get(Repository::class))
        );
        $commandBus->installExecutor(
            UpdateLatestClosure::class,
            new UpdateLatestClosureExecutor($container->get(Repository::class))
        );
    }
}