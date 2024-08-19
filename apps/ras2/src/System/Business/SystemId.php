<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Business;

use Ramsey\Uuid\Uuid;
use Ramsey\Uuid\UuidInterface;

final class SystemId implements \Stringable
{
    private function __construct(
        private UuidInterface $id
    ) {
    }

    public function __toString(): string
    {
        return $this->id->toString();
    }

    public static function fromString(string $input): self
    {
        return new self(Uuid::fromString($input));
    }
}
