<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Attribute;

#[Attribute(Attribute::TARGET_PROPERTY)]
final readonly class ValueType implements HydrationAttribute
{
    /**
     * @param class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL' $typeName
     */
    public function __construct(
        public string $typeName
    ) {
    }
}
