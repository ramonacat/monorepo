<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

final class CannotHydrateType extends \RuntimeException
{
    public static function for(string $targetType): self
    {
        return new self("Cannot hydrate type '{$targetType}'");
    }
}
