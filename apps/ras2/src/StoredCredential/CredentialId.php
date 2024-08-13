<?php

declare(strict_types=1);

namespace Ramona\Ras2\StoredCredential;

use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class CredentialId
{
    private function __construct(
        private UuidInterface $id
    ) {
    }

    public function __toString(): string
    {
        return $this->id->toString();
    }

    public static function fromString(string $raw): self
    {
        return new self(Uuid::fromString($raw));
    }

    public static function generate(): self
    {
        return new self(Uuid::uuid7());
    }
}
