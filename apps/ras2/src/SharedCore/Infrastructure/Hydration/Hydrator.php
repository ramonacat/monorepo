<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

use Ramona\Ras2\User\Application\Session;

interface Hydrator
{
    /**
     * @template T
     * @param ValueHydrator<T> $valueHydrator
     */
    public function installValueHydrator(ValueHydrator $valueHydrator): void;

    /**
     * @template T
     *
     * @param class-string<T>|'float'|'integer'|'int'|'bool'|'string'|'array'|'boolean'|'resource'|'NULL' $targetType
     * @param list<HydrationAttribute> $attributes
     * @return T
     */
    public function hydrate(string $targetType, mixed $input, array $attributes = []): mixed;

    public function setSession(?Session $session): void;

    public function session(): ?Session;
}
