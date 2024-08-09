<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Serialization;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @implements ValueDehydrator<ArrayCollection<array-key, mixed>>
 */
final class ArrayCollectionDehydrator implements ValueDehydrator
{
    public function dehydrate(Dehydrator $dehydrator, mixed $value): mixed
    {
        return $value
            ->map($dehydrator->dehydrate(...))
            ->toArray();
    }

    public function handles(): string
    {
        return ArrayCollection::class;
    }
}
