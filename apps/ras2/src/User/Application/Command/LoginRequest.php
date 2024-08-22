<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Command;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;

final readonly class LoginRequest implements Command
{
    public function __construct(
        public string $username
    ) {
    }
}
