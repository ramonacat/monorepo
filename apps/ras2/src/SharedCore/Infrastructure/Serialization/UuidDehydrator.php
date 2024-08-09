<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Ramsey\Uuid\UuidInterface;

/**
 * @implements ValueDehydrator<UuidInterface>
 */
final class UuidDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return $value->toString();
    }

    public function handles(): string
    {
        return UuidInterface::class;
    }
}
