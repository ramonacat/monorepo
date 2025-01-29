<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;
use Ramsey\Uuid\UuidInterface;

/**
 * @implements ValueDehydrator<UuidInterface>
 */
final class UuidDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): string
    {
        return $value->toString();
    }

    /**
     * @return class-string<UuidInterface>
     */
    public function handles(): string
    {
        return UuidInterface::class;
    }
}
