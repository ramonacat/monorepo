<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration;

interface Dehydrator
{
    /**
     * @template T
     * @param ValueDehydrator<T> $valueDehydrator
     */
    public function installValueDehydrator(ValueDehydrator $valueDehydrator): void;

    public function dehydrate(mixed $value): mixed;
}
