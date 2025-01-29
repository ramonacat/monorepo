<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query;

use DI\Container;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\DefaultQueryBus;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\NoExecutor;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQuery;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQueryExecutor;
use Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks\MockQueryWithoutExecutor;

final class BusTest extends TestCase
{
    public function testCanDispatchAQuery(): void
    {
        $bus = new DefaultQueryBus(new Container());
        $bus->installExecutor(MockQuery::class, new MockQueryExecutor());

        $query = new MockQuery();

        $result = $bus->execute($query);

        self::assertSame($query->value, $result->value);
    }

    public function testFailsOnMissingExecutor(): void
    {
        $bus = new DefaultQueryBus(new Container());

        $this->expectException(NoExecutor::class);
        $bus->execute(new MockQueryWithoutExecutor());
    }

    public function testCanUseExecutorFromAttribute(): void
    {
        $executor = new MockQueryExecutor();

        $container = new Container();
        $container->set(MockQueryExecutor::class, $executor);

        $bus = new DefaultQueryBus($container);

        $response = $bus->execute(new MockQuery());

        self::assertEquals('test1234', $response->value);
    }
}
