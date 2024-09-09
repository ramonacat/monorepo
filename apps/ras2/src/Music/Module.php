<?php

declare(strict_types=1);

namespace Ramona\Ras2\Music;

use DI\ContainerBuilder;
use Psr\Container\ContainerInterface;

final class Module implements \Ramona\Ras2\SharedCore\Infrastructure\Module\Module
{
    public function install(ContainerBuilder $containerBuilder): void
    {
        $containerBuilder->addDefinitions([]);
    }

    public function register(ContainerInterface $container): void
    {
    }
}
