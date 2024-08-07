<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks;

final class Simple
{
    public function __construct(
        public string $id = 'test',
        public ?int $stuff = 1234
    ) {
    }
}
