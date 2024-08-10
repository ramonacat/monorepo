<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Command;

use Ramona\Ras2\User\Business\Token;

final class LoginResponse
{
    public function __construct(
        public Token $token
    ) {
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function token(): Token
    {
        return $this->token;
    }
}
