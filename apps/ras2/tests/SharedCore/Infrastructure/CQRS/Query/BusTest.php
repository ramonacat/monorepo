<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\DefaultQueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\NoExecutor;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQuery;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQueryExecutor;

final class BusTest extends TestCase
{
    public function testCanDispatchAQuery(): void
    {
        $bus = new DefaultQueryBus();
        $bus->installExecutor(MockQuery::class, new MockQueryExecutor());

        $query = new MockQuery();

        $result = $bus->execute($query);

        self::assertSame($query->value, $result->value);
    }

    public function testFailsOnMissingExecutor(): void
    {
        $bus = new DefaultQueryBus();

        $this->expectException(NoExecutor::class);
        $bus->execute(new MockQuery());
    }
}
