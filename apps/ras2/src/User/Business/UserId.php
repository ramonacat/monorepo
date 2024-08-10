<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Business;

use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class UserId implements \Stringable
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
