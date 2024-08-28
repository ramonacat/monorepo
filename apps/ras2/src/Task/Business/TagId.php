<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Ramona\Ras2\SharedCore\Business\Identifier;
use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class TagId implements Identifier
{
    private UuidInterface $id;

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(UuidInterface $id)
    {
        $this->id = $id;
    }

    public function __toString(): string
    {
        return $this->id->toString();
    }

    public static function generate(): self
    {
        return new self(Uuid::uuid7());
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public static function fromString(string $id): self
    {
        return new self(Uuid::fromString($id));
    }
}
