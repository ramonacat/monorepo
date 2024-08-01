<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramsey\Uuid\UuidInterface;

final class TagId
{
    /**
     * @psalm-suppress UnusedProperty
     * @phpstan-ignore property.onlyWritten
     */
    private UuidInterface $id;

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(UuidInterface $id)
    {
        $this->id = $id;
    }
}
