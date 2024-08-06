<?php

declare(strict_types=1);

use Laminas\Diactoros\ResponseFactory;
use League\Route\Strategy\JsonStrategy;
use Ramona\Ras2\CQRS\Command\Bus as CommandBus;
use Ramona\Ras2\Task\Command\Executor\CreateIdeaExecutor;
use Ramona\Ras2\Task\HttpApi\CreateIdea;
use Ramona\Ras2\Task\PostgresRepository;

require_once __DIR__ . '/../vendor/autoload.php';

$databaseConnection = \Doctrine\DBAL\DriverManager::getConnection(require __DIR__ . '/../migrations-db.php');

$commandBus = new CommandBus();
$commandBus->installExecutor(
    \Ramona\Ras2\Task\Command\CreateIdea::class,
    new CreateIdeaExecutor(new PostgresRepository($databaseConnection))
);
$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);

$serializer = (new \Ramona\Ras2\Serialization\SerializerFactory())->create();

$responseFactory = new ResponseFactory();
$routerStrategy = new JsonStrategy($responseFactory);

$router = new League\Route\Router();
$router->setStrategy($routerStrategy);
$router->map('POST', '/tasks/ideas', new CreateIdea($commandBus, $serializer));
$response = $router->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
