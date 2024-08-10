<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrationAttribute;

interface Deserializer
{
    /**
     * @template T
     * @param 'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL'|class-string<T> $targetType
     * @param list<HydrationAttribute> $attributes
     * @return T
     */
    public function deserialize(string $targetType, string $raw, array $attributes = []): mixed;
}
