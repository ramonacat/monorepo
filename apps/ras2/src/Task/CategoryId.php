<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class CategoryId
{
    /**
     * @psalm-suppress UnusedProperty
     * @phpstan-ignore property.onlyWritten
     */
    private UuidInterface $id;

    public function __construct(UuidInterface $id)
    {
        $this->id = $id;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public static function generate(): self
    {
        return new self(Uuid::uuid7());
    }

    public static function fromString(string $raw): self
    {
        return new self(Uuid::fromString($raw));
    }
}
