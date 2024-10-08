<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use RuntimeException;

final class CannotDehydrateType extends RuntimeException
{
    public static function for(string $string): self
    {
        return new self("Cannot dehydrate type '{$string}'");
    }
}
