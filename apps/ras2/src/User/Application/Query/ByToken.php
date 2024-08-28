<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\User\Application\Session;
use Ramona\Ras2\User\Business\Token;
use Ramona\Ras2\User\Infrastructure\QueryExecutor\ByTokenExecutor;

/**
 * @implements Query<Session>
 */
#[ExecutedBy(ByTokenExecutor::class)]
final readonly class ByToken implements Query
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
