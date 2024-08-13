<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Application\CurrentTaskView;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements Query<?CurrentTaskView>
 */
final class Current implements Query
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public UserId $userId
    ) {
    }
}
