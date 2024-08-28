<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Module;

use DI\ContainerBuilder;
use Psr\Container\ContainerInterface;

interface Module
{
    /**
     * @template T of \DI\Container
     * @param ContainerBuilder<T> $containerBuilder
     */
    public function install(ContainerBuilder $containerBuilder): void;

    public function register(ContainerInterface $container): void;
}
