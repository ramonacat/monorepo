<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\CQRS\Query;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\CQRS\Query\Bus;
use Tests\Ramona\Ras2\CQRS\Query\Mocks\MockQuery;
use Tests\Ramona\Ras2\CQRS\Query\Mocks\MockQueryExecutor;

final class BusTest extends TestCase
{
    public function testCanDispatchAQuery(): void
    {
        $bus = new Bus();
        $bus->installExecutor(MockQuery::class, new MockQueryExecutor());

        $query = new MockQuery();

        $result = $bus->execute($query);

        self::assertSame($query->value, $result);
    }
}
