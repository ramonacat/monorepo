<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event;

use League\Route\Router;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;
use Ramona\Ras2\StoredCredential\Api;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(GetEvents::class, fn (Container $c) => new GetEvents($c->get(Api::class)));
    }

    public function register(Container $container): void
    {
        $router = $container->get(Router::class);
        $router->map('GET', '/events', GetEvents::class);
    }
}
