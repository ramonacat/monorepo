<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

/**
 * @implements Query<MockResponse>
 */
final class MockQueryWithoutExecutor implements Query
{
}
