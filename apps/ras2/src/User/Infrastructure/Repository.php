<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Infrastructure;

use Closure;
use Ramona\Ras2\User\Business\Token;
use Ramona\Ras2\User\Business\User;

interface Repository
{
    /**
     * @param Closure():void $callable
     */
    public function transactional(Closure $callable): void;

    public function save(User $user): void;

    public function assignTokenByUsername(string $name, Token $token): void;
}
