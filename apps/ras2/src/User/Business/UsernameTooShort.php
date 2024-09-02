<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Business;

use RuntimeException;

final class UsernameTooShort extends RuntimeException
{
    public static function forName(string $name): self
    {
        return new self("Username \"{$name}\" is too short");
    }
}
