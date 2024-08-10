<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Command;

final readonly class LoginRequest
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public string $username
    ) {
    }
}
