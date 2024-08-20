<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Ramona\Ras2\User\Business\UserId;

final class ProfileNotFound extends \RuntimeException
{
    public static function forUser(UserId $userId): self
    {
        return new self("No profile found for user {$userId}");
    }
}
