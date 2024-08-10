<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\Token;

/**
 * @implements Query<Session>
 */
final readonly class FindByToken implements Query
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
