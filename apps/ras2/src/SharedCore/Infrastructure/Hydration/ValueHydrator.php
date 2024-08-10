<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

/**
 * @template-covariant  T
 */
interface ValueHydrator
{
    /**
     * @param list<HydrationAttribute> $serializationAttributes
     * @return T
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed;

    /**
     * @return class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL'
     */
    public function handles(): string;
}
