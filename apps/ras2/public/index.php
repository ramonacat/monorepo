<?php

declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

use Doctrine\DBAL\DriverManager;
use Ramona\Ras2\Task\Query\Executor\AllTasksByCategoryExecutor;
use Ramona\Ras2\Task\Web\ListController;

$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);

$databaseConnection = DriverManager::getConnection(require __DIR__ . '/../migrations-db.php');

$router = new League\Route\Router();
$router->map('GET', '/', new ListController(new AllTasksByCategoryExecutor($databaseConnection)));
$response = $router->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
