<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Container;
use Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\NotFound;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Mocks\A;

final class ContainerTest extends TestCase
{
    public function testThrowsIfServiceDoesNotExist(): void
    {
        $container = new Container([]);

        $this->expectException(NotFound::class);
        $this->expectExceptionMessage(
            "A factory for 'Tests\Ramona\Ras2\SharedCore\Infrastructure\DependencyInjection\Mocks\A' was not found in the container"
        );
        $container->get(A::class);
    }
}
