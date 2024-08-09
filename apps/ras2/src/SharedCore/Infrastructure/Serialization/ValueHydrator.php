<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

/**
 * @template T
 */
interface ValueHydrator
{
    /**
     * @param list<SerializationAttribute> $serializationAttributes
     * @return T
     */
    public function hydrate(Hydrator $hydrator, mixed $input, array $serializationAttributes): mixed;

    /**
     * @return class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL'
     */
    public function handles(): string;
}
