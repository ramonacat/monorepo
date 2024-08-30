<?php

declare(strict_types=1);

namespace Task\Business;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Business\FilterId;

final class FilterIdTest extends TestCase
{
    public function testCanBeCreatedFromString(): void
    {
        $id = FilterId::fromString('0191a41a-11ef-79a3-8bd3-54a440fedb51');

        self::assertEquals('0191a41a-11ef-79a3-8bd3-54a440fedb51', (string) $id);
    }
}
