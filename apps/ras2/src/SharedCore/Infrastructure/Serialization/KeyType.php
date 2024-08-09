<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

#[\Attribute(\Attribute::TARGET_PROPERTY)]
final readonly class KeyType implements SerializationAttribute
{
    /**
     * @param 'integer'|'string' $typeName
     */
    public function __construct(
        public string $typeName
    ) {
    }
}
