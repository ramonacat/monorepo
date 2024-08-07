<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

/**
 * @implements Query<string>
 */
final class MockQuery implements Query
{
    public string $value = 'test1234';
}
