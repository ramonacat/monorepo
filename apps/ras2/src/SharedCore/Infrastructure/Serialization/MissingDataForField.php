<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

final class MissingDataForField extends \RuntimeException
{
    public static function field(string $propertyName): self
    {
        return new self(sprintf('No data found for property "%s"', $propertyName));
    }

    public static function isNull(string $propertyName): self
    {
        return new self(sprintf('Data for non-nullable property "%s" is null', $propertyName));
    }
}
