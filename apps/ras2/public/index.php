<?php

declare(strict_types=1);

use League\Route\Router;

require_once __DIR__ . '/../vendor/autoload.php';

$diContainer = require '../src/container.php';
$request = Laminas\Diactoros\ServerRequestFactory::fromGlobals($_SERVER, $_GET, $_POST, $_COOKIE, $_FILES);
$response = $diContainer->get(Router::class)->dispatch($request);

// send the response to the browser
(new Laminas\HttpHandlerRunner\Emitter\SapiEmitter())->emit($response);
