<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

final class User
{
    public function __construct(
        private UserId $id,
        private string $name
    ) {
        if (grapheme_strlen($name) < 3) {
            throw UsernameTooShort::forName($name);
        }
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function id(): UserId
    {
        return $this->id;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function name(): string
    {
        return $this->name;
    }
}
