<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\User\Token;

final class Login implements Command
{
    public function __construct(
        public Token $token,
        public string $username
    ) {
    }
}
