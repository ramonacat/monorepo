<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Module;

use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\ContainerBuilder;

interface Module
{
    public function install(ContainerBuilder $containerBuilder): void;

    public function register(Container $container): void;
}
