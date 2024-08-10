<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

class InvalidArrayDeclaration extends \RuntimeException
{
    public static function missingKeyOrValue(): self
    {
        return new self('Property declaration is missing key or value.');
    }
}
