<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

/**
 * A value dehydrator takes a value of type T and transforms it into a scalar, or an array of scalars (or array of arrays of scalars, etc.)
 * @template T
 */
interface ValueDehydrator
{
    /**
     * @param T $value
     */
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed;

    /**
     * @return class-string|'float'|'integer'|'string'|'array'|'boolean'|'resource'|'NULL'
     */
    public function handles(): string;
}
