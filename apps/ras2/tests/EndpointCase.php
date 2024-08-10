<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2;

use PHPUnit\Framework\TestCase;

abstract class EndpointCase extends TestCase
{
    protected mixed $container;

    protected function setUp(): void
    {
        $this->container = require __DIR__ . '/../src/container.php';
    }
}
