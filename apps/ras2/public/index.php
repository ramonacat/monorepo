<?php

declare(strict_types=1);

use League\Route\Router;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIDefinition;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIRouter;

require_once __DIR__ . '/../vendor/autoload.php';

$diContainer = require __DIR__ . '/../src/container.php';
$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);
$router = $diContainer->get(Router::class);
$apiDefinition = $diContainer->get(APIDefinition::class);
$apiRouter = $diContainer->get(APIRouter::class);
$apiRouter->register($apiDefinition, $router);
$response = $router->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
