<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\User\Business\Token;

final class Login implements Command
{
    public function __construct(
        public Token $token,
        public string $username
    ) {
    }
}
