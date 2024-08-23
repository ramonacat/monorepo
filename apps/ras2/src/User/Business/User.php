<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Business;

final class User
{
    public function __construct(
        private UserId $id,
        private string $name,
        private bool $isSystem,
        private \DateTimeZone $timezone
    ) {
        if (grapheme_strlen($name) < 3) {
            throw UsernameTooShort::forName($name);
        }
    }

    public function id(): UserId
    {
        return $this->id;
    }

    public function name(): string
    {
        return $this->name;
    }

    public function isSystem(): bool
    {
        return $this->isSystem;
    }

    public function timezone(): \DateTimeZone
    {
        return $this->timezone;
    }
}
