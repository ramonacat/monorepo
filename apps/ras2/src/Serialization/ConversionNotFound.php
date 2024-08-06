<?php

declare(strict_types=1);

namespace Ramona\Ras2\Serialization;

final class ConversionNotFound extends \RuntimeException
{
    public static function forValue(mixed $value, string $typeName): self
    {
        return new self(
            sprintf(
                'No conversion found for value "%s" of type "%s" to "%s"',
                \Safe\json_encode($value),
                get_debug_type($value),
                $typeName
            )
        );
    }
}
