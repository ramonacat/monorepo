<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure;

use Laminas\Diactoros\ResponseFactory;
use League\Route\Router;
use League\Route\Strategy\JsonStrategy;
use Psr\Container\ContainerInterface;
use Psr\Log\LoggerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\QueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\LogRequests;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RequireLogin;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\RouteStrategy;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;

final class RouterFactory
{
    public static function create(ContainerInterface $container): Router
    {
        $responseFactory = new ResponseFactory();
        $jsonStrategy = new JsonStrategy($responseFactory);
        $jsonStrategy->setContainer($container);
        $routerStrategy = new RouteStrategy($jsonStrategy, new LogRequests($container->get(LoggerInterface::class)));

        $router = new Router();
        $router->setStrategy($routerStrategy);
        $router->prependMiddleware(
            new RequireLogin($container->get(QueryBus::class), $container->get(Hydrator::class))
        );

        return $router;
    }
}
