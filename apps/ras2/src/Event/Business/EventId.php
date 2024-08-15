<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Business;

use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class EventId implements \Stringable
{
    private function __construct(
        private UuidInterface $id
    ) {
    }

    public function __toString(): string
    {
        return $this->id->toString();
    }

    public static function generate(): self
    {
        return new self(Uuid::uuid7());
    }

    public static function fromString(string $input): self
    {
        return new self(Uuid::fromString($input));
    }
}
