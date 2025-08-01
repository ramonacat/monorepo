<?php

declare(strict_types=1);

use DI\ContainerBuilder;
use Doctrine\DBAL\Connection;
use League\Route\Router;
use Psr\Container\ContainerInterface;
use Psr\Log\LoggerInterface;
use Psr\SimpleCache\CacheInterface;
use Ramona\Ras2\Event\Module as EventModule;
use Ramona\Ras2\Maintenance\Module as MaintenanceModule;
use Ramona\Ras2\SharedCore\Infrastructure\Clock;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\DefaultCommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\DefaultQueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DatabaseConnectionFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinitionFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\DefaultJsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DehydratorFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydratorFactory;
use Ramona\Ras2\SharedCore\Infrastructure\LoggerFactory;
use Ramona\Ras2\SharedCore\Infrastructure\MustacheFactory;
use Ramona\Ras2\SharedCore\Infrastructure\RouterFactory;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDeserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultSerializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\SharedCore\Infrastructure\SystemClock;
use Ramona\Ras2\System\Module as SystemModule;
use Ramona\Ras2\Task\Module as TaskModule;
use Ramona\Ras2\User\Module as UserModule;
use Symfony\Component\Cache\Adapter\FilesystemAdapter;
use Symfony\Component\Cache\Psr16Cache;

$containerBuilder = new ContainerBuilder();
$containerBuilder->useAutowiring(true)
    ->useAttributes(false);

$containerBuilder->addDefinitions([
    CommandBus::class => fn (ContainerInterface $c) => new DefaultCommandBus($c),
    QueryBus::class => fn (ContainerInterface $c) => new DefaultQueryBus($c),
    LoggerInterface::class => fn () => LoggerFactory::create(),
    Connection::class => fn () => DatabaseConnectionFactory::create('ras2'),
    'db.telegraf' => fn () => DatabaseConnectionFactory::create('telegraf'),
    Hydrator::class => fn () => HydratorFactory::create(),
    Dehydrator::class => fn () => DehydratorFactory::create(),
    Router::class => fn (ContainerInterface $c) => RouterFactory::create($c),
    Serializer::class => fn (ContainerInterface $c) => new DefaultSerializer(
        $c->get(Dehydrator::class),
        $c->get(LoggerInterface::class)
    ),
    Deserializer::class => fn (ContainerInterface $c) => new DefaultDeserializer(
        $c->get(Hydrator::class),
        $c->get(LoggerInterface::class)
    ),
    Clock::class => fn () => new SystemClock(),
    JsonResponseFactory::class => fn (ContainerInterface $c) => new DefaultJsonResponseFactory($c->get(
        Serializer::class
    )),
    APIDefinition::class => fn (ContainerInterface $c) => APIDefinitionFactory::create($c),
    CacheInterface::class => fn () => new Psr16Cache(new FilesystemAdapter()),
    \Mustache\Engine::class => fn () => MustacheFactory::create(),
]);

$modules = [new TaskModule(), new UserModule(), new EventModule(), new SystemModule(), new MaintenanceModule()];

foreach ($modules as $module) {
    $module->install($containerBuilder);
}

$container = $containerBuilder->build();

foreach ($modules as $module) {
    $module->register($container);
}

return $container;
