<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

#[\Attribute(\Attribute::TARGET_PROPERTY)]
final readonly class KeyType implements HydrationAttribute
{
    /**
     * @param 'integer'|'string' $typeName
     */
    public function __construct(
        public string $typeName
    ) {
    }
}
