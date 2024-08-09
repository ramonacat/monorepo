<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

#[\Attribute(\Attribute::TARGET_PROPERTY)]
final readonly class ValueType implements SerializationAttribute
{
    /**
     * @param class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $typeName
     */
    public function __construct(
        public string $typeName
    ) {
    }
}
