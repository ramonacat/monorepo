<?php

declare(strict_types=1);

namespace Ramona\Ras2\User;

final class UserNotFound extends \RuntimeException
{
    public static function forName(string $name): self
    {
        return new self("Cannot find user for name \"{$name}\"");
    }
}
