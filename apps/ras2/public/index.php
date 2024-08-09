<?php

declare(strict_types=1);

use Doctrine\DBAL\DriverManager;
use Laminas\Diactoros\ResponseFactory;
use League\Route\Strategy\JsonStrategy;
use Monolog\Formatter\LineFormatter;
use Monolog\Handler\StreamHandler;
use Monolog\Logger;
use Ramona\Ras2\SharedCore\Application\DeserializerFactory;
use Ramona\Ras2\SharedCore\Application\SerializerFactory;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Bus as CommandBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus as QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\LogExceptions;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RouteStrategy;
use Ramona\Ras2\Task\Command\Executor\CreateIdeaExecutor;
use Ramona\Ras2\Task\Command\Executor\UpsertBacklogItemExecutor;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Command\UpsertIdea;
use Ramona\Ras2\Task\HttpApi\GetTasks;
use Ramona\Ras2\Task\HttpApi\PostTasks;
use Ramona\Ras2\Task\PostgresRepository;
use Ramona\Ras2\Task\Query\Executor\FindUpcomingExecutor;
use Ramona\Ras2\Task\Query\FindUpcoming;
use Ramona\Ras2\User\Command\Executor\LoginExecutor;
use Ramona\Ras2\User\Command\Executor\UpsertUserExecutor;
use Ramona\Ras2\User\Command\Login;
use Ramona\Ras2\User\Command\UpsertUser;
use Ramona\Ras2\User\HttpApi\PostUser;
use Ramona\Ras2\User\Query\Executor\FindByTokenExecutor;
use Ramona\Ras2\User\Query\FindByToken;

require_once __DIR__ . '/../vendor/autoload.php';

$logger = new Logger('ras2');
$handler = new StreamHandler('php://stderr');
$handler->setFormatter(new LineFormatter(includeStacktraces: true));
$logger->pushHandler($handler);

$databaseConnection = DriverManager::getConnection(require __DIR__ . '/../migrations-db.php');

$postgresRepository = new PostgresRepository($databaseConnection);
$postgresUserRepository = new \Ramona\Ras2\User\PostgresRepository($databaseConnection);
$commandBus = new CommandBus();
$commandBus->installExecutor(UpsertIdea::class, new CreateIdeaExecutor($postgresRepository));
$commandBus->installExecutor(UpsertBacklogItem::class, new UpsertBacklogItemExecutor($postgresRepository));
$commandBus->installExecutor(UpsertUser::class, new UpsertUserExecutor($postgresUserRepository));
$commandBus->installExecutor(Login::class, new LoginExecutor($postgresUserRepository));

$queryBus = new QueryBus();
$queryBus->installExecutor(FindByToken::class, new FindByTokenExecutor($databaseConnection));
$queryBus->installExecutor(FindUpcoming::class, new FindUpcomingExecutor($databaseConnection));
$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);

$serializer = (new SerializerFactory())->create();
$deserializer = (new DeserializerFactory())->create();

$responseFactory = new ResponseFactory();
$routerStrategy = new RouteStrategy(new JsonStrategy($responseFactory), new LogExceptions($logger));

$router = new League\Route\Router();
$router->setStrategy($routerStrategy);
$router->prependMiddleware(new RequireLogin($queryBus));
$router->map('GET', '/tasks', new GetTasks($queryBus, $serializer));
$router->map('POST', '/tasks', new PostTasks($commandBus, $deserializer));
$router->map('POST', '/users', new PostUser($commandBus, $serializer, $deserializer));
$response = $router->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
