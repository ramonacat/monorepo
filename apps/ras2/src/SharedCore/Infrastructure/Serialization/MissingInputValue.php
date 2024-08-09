<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

final class MissingInputValue extends \RuntimeException
{
    public static function forProperty(string $propertyName): self
    {
        return new self("No value was provided for field '{$propertyName}'");
    }
}
