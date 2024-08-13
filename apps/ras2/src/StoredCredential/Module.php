<?php

declare(strict_types=1);

namespace Ramona\Ras2\StoredCredential;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->register(Api::class, fn (Container $c) => new DefaultApi($c->get(Connection::class)));
    }

    public function register(Container $container): void
    {
    }
}
