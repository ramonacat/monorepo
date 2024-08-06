<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Serialization\Mocks;

final class UnionType
{
    public function __construct(
        public string|float $field
    ) {
    }
}
