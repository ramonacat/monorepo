<?php

declare(strict_types=1);

namespace Ramona\Ras2\StoredCredential;

use Ramona\Ras2\User\Business\UserId;

final class NotFound extends \RuntimeException
{
    public static function forNameAndUser(string $name, UserId $owner): self
    {
        return new self("No credential '{$name}' found for user '{$owner}'");
    }
}
