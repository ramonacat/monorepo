<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Ramona\Ras2\SharedCore\Business\Identifier;
use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class TaskId implements Identifier
{
    private function __construct(
        private UuidInterface $id
    ) {
    }

    public function __toString(): string
    {
        return $this->id->toString();
    }

    public static function fromString(string $id): static
    {
        return new self(Uuid::fromString($id));
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public static function generate(): static
    {
        return new self(Uuid::uuid7());
    }
}
