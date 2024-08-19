<?php

declare(strict_types=1);

use Doctrine\DBAL\Connection;
use Doctrine\DBAL\DriverManager;
use Laminas\Diactoros\ResponseFactory;
use League\Route\Router;
use League\Route\Strategy\JsonStrategy;
use Monolog\Formatter\LineFormatter;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\SyslogHandler;
use Monolog\Logger;
use Psr\Log\LoggerInterface;
use Psr\Log\NullLogger;
use Ramona\Ras2\Event\Module as EventModule;
use Ramona\Ras2\SharedCore\Infrastructure\ClockInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\CommandExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\DefaultCommandExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\JsonResponseFactory;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\LogRequests;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RouteStrategy;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\DefaultDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ArrayCollectionDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\DateTimeImmutableDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\ScalarDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator\UuidDehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ArrayCollectionHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\DateTimeImmutableHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator\ScalarHydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultDeserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\DefaultSerializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Deserializer;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\Serializer;
use Ramona\Ras2\SharedCore\Infrastructure\SystemClock;
use Ramona\Ras2\System\Module as SystemModule;
use Ramona\Ras2\Task\Module as TaskModule;
use Ramona\Ras2\User\Module as UserModule;

$containerBuilder = new ContainerBuilder();
$containerBuilder->register(ClockInterface::class, fn () => new SystemClock());
$containerBuilder->register(LoggerInterface::class, function () {
    $applicationMode = getenv('APPLICATION_MODE');

    if ($applicationMode === 'test') {
        return new NullLogger();
    }

    $logger = new Logger('ras2');
    if ($applicationMode !== 'prod') {
        $handler = new StreamHandler('php://stderr');
        $handler->setFormatter(new LineFormatter(includeStacktraces: true));
    } else {
        $handler = new SyslogHandler('ras2');
    }
    $logger->pushHandler($handler);

    return $logger;
});
$containerBuilder->register(
    Connection::class,
    function () {
        $config = require __DIR__ . '/../migrations-db.php';

        return DriverManager::getConnection($config);
    }
);
$containerBuilder->register(CommandBus::class, fn () => new CommandBus());
$containerBuilder->register(QueryBus::class, fn () => new QueryBus());
$containerBuilder->register(
    Serializer::class,
    fn (Container $c) => new DefaultSerializer($c->get(Dehydrator::class), $c->get(LoggerInterface::class))
);
$containerBuilder->register(Hydrator::class, function () {
    $hydrator = new Hydrator();
    $hydrator->installValueHydrator(new ScalarHydrator('string'));
    $hydrator->installValueHydrator(new ScalarHydrator('integer'));
    $hydrator->installValueHydrator(new ArrayCollectionHydrator());
    $hydrator->installValueHydrator(new DateTimeImmutableHydrator());

    return $hydrator;
});
$containerBuilder->register(
    Deserializer::class,
    fn (Container $c) => new DefaultDeserializer($c->get(Hydrator::class), $c->get(LoggerInterface::class))
);

$containerBuilder->register(Dehydrator::class, function () {
    $dehydrator = new DefaultDehydrator();
    $dehydrator->installValueDehydrator(new ArrayCollectionDehydrator());
    $dehydrator->installValueDehydrator(new ScalarDehydrator('integer'));
    $dehydrator->installValueDehydrator(new ScalarDehydrator('string'));
    $dehydrator->installValueDehydrator(new ScalarDehydrator('boolean'));
    $dehydrator->installValueDehydrator(new ScalarDehydrator('NULL'));
    $dehydrator->installValueDehydrator(new UuidDehydrator());
    $dehydrator->installValueDehydrator(new DateTimeImmutableDehydrator());

    return $dehydrator;
});

$containerBuilder->register(
    Serializer::class,
    fn (Container $c) => new DefaultSerializer($c->get(Dehydrator::class), $c->get(LoggerInterface::class))
);

$containerBuilder->register(Router::class, function (Container $diContainer) {
    $responseFactory = new ResponseFactory();
    $jsonStrategy = new JsonStrategy($responseFactory);
    $jsonStrategy->setContainer($diContainer);
    $routerStrategy = new RouteStrategy($jsonStrategy, new LogRequests($diContainer->get(LoggerInterface::class)));

    $router = new League\Route\Router();
    $router->setStrategy($routerStrategy);
    $router->prependMiddleware(new RequireLogin($diContainer->get(QueryBus::class)));

    return $router;
});

$containerBuilder->register(JsonResponseFactory::class, fn ($c) => new JsonResponseFactory($c->get(Serializer::class)));
$containerBuilder->register(
    CommandExecutor::class,
    fn ($c) => new DefaultCommandExecutor($c->get(Deserializer::class), $c->get(CommandBus::class))
);

$modules = [new TaskModule(), new UserModule(), new EventModule(), new SystemModule()];

foreach ($modules as $module) {
    $module->install($containerBuilder);
}

$builtContainer = $containerBuilder->build();

foreach ($modules as $module) {
    $module->register($builtContainer);
}

return $builtContainer;
