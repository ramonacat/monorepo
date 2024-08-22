<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Mocks;

final readonly class MockResponse
{
    public function __construct(
        public string $value
    ) {
    }
}
