<?php

declare(strict_types=1);

namespace Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Dehydrator;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueDehydrator;

/**
 * @implements ValueDehydrator<ArrayCollection<array-key, mixed>>
 */
final class ArrayCollectionDehydrator implements ValueDehydrator
{
    /**
     * @return array<array-key, mixed>
     */
    public function dehydrate(Dehydrator $dehydrator, mixed $value): array
    {
        return $value
            ->map($dehydrator->dehydrate(...))
            ->toArray();
    }

    /**
     * @return class-string<ArrayCollection<array-key, mixed>>
     */
    public function handles(): string
    {
        return ArrayCollection::class;
    }
}
