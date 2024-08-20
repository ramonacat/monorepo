<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application;

use Ramona\Ras2\User\Business\UserId;

final readonly class Session
{
    public function __construct(
        public UserId $userId,
        public string $username
    ) {
    }
}
