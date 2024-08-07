<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Bus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutorNotFound;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQuery;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQueryExecutor;

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

    public function testFailsOnMissingExecutor(): void
    {
        $bus = new Bus();

        $this->expectException(ExecutorNotFound::class);
        $bus->execute(new MockQuery());
    }
}
