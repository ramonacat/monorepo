<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition;

use Psr\Container\ContainerInterface;
use Ramona\Ras2\SharedCore\Infrastructure\ClassFinder;

final class APIDefinitionFactory
{
    public static function create(ContainerInterface $container): APIDefinition
    {
        $result = new APIDefinition($container->get(ClassFinder::class));
        $result->installQueriesFromAttributes();
        $result->installCommandsFromAttributes();

        return $result;
    }
}
