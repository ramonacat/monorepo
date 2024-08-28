<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Ramona\Ras2\SharedCore\Business\Identifier;
use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class TaskId implements Identifier
{
    private UuidInterface $id;

    public function __construct(UuidInterface $id)
    {
        $this->id = $id;
    }

    public function __toString(): string
    {
        return $this->id->toString();
    }

    public static function fromString(string $id): self
    {
        return new self(Uuid::fromString($id));
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public static function generate(): self
    {
        return new self(Uuid::uuid7());
    }
}
