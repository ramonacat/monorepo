<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\SharedCore\Infrastructure\Serialization\Mocks;

final class UntypedProperty
{
    /**
     * @phpstan-ignore missingType.parameter
     */
    public function __construct(
        public $untyped
    ) {
    }
}
