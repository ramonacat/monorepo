<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

final class ConversionNotFound extends \RuntimeException
{
    public static function forValue(mixed $value, string $typeName): self
    {
        $encodedValue = is_resource($value) ? (string) $value : \Safe\json_encode($value);

        return new self(
            sprintf(
                'No conversion found for value "%s" of type "%s" to "%s"',
                $encodedValue,
                get_debug_type($value),
                $typeName
            )
        );
    }
}
