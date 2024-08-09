<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

interface Deserializer
{
    /**
     * @template T
     * @param 'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL'|class-string<T> $targetType
     * @return T
     */
    public function deserialize(string $targetType, string $raw): mixed;
}
