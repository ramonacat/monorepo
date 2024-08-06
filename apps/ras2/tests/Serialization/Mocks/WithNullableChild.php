<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Serialization\Mocks;

final class WithNullableChild
{
    public function __construct(
        public ?Simple $child,
        public int $test
    ) {
    }
}
