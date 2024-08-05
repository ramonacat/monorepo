<?php

declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);

$router = new League\Route\Router();
$router->map('GET', '/', function () {
    $response = new \Laminas\Diactoros\Response();
    $response->getBody()
        ->write('hello world');

    return $response;
});
$response = $router->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
