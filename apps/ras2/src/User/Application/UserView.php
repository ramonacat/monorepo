<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application;

use Ramona\Ras2\User\Business\UserId;

final readonly class UserView
{
    public function __construct(
        public UserId $id,
        public string $username
    ) {
    }
}
