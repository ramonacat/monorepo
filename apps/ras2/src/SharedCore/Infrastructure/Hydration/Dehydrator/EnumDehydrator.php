<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @template T of \UnitEnum
 * @implements ValueDehydrator<T>
 */
final class EnumDehydrator implements ValueDehydrator
{
    /**
     * @param class-string<T> $handles
     */
    public function __construct(
        private string $handles
    ) {

    }

    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return $value->name;
    }

    public function handles(): string
    {
        return $this->handles;
    }
}
