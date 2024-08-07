<?php

declare(strict_types=1);

use Doctrine\DBAL\DriverManager;
use Laminas\Diactoros\ResponseFactory;
use League\Route\Strategy\JsonStrategy;
use Ramona\Ras2\CQRS\Command\Bus as CommandBus;
use Ramona\Ras2\Infrastructure\SerializerFactory;
use Ramona\Ras2\Task\Command\Executor\CreateBacklogItemExecutor;
use Ramona\Ras2\Task\Command\Executor\CreateIdeaExecutor;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Command\UpsertIdea;
use Ramona\Ras2\Task\HttpApi\CreateTask;
use Ramona\Ras2\Task\PostgresRepository;
use Ramona\Ras2\User\Command\Executor\LoginExecutor;
use Ramona\Ras2\User\Command\Executor\UpsertUserExecutor;
use Ramona\Ras2\User\Command\Login;
use Ramona\Ras2\User\Command\UpsertUser;
use Ramona\Ras2\User\HttpApi\PostUser;

require_once __DIR__ . '/../vendor/autoload.php';

$databaseConnection = DriverManager::getConnection(require __DIR__ . '/../migrations-db.php');

$postgresRepository = new PostgresRepository($databaseConnection);
$postgresUserRepository = new \Ramona\Ras2\User\PostgresRepository($databaseConnection);
$commandBus = new CommandBus();
$commandBus->installExecutor(UpsertIdea::class, new CreateIdeaExecutor($postgresRepository));
$commandBus->installExecutor(UpsertBacklogItem::class, new CreateBacklogItemExecutor($postgresRepository));
$commandBus->installExecutor(UpsertUser::class, new UpsertUserExecutor($postgresUserRepository));
$commandBus->installExecutor(Login::class, new LoginExecutor($postgresUserRepository));

$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);

$serializer = (new SerializerFactory())->create();

$responseFactory = new ResponseFactory();
$routerStrategy = new JsonStrategy($responseFactory);

$router = new League\Route\Router();
$router->setStrategy($routerStrategy);
$router->map('POST', '/tasks', new CreateTask($commandBus, $serializer));
$router->map('POST', '/users', new PostUser($commandBus, $serializer));
$response = $router->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
