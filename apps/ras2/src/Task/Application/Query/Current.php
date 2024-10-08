<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrateFromSession;
use Ramona\Ras2\Task\Application\CurrentTaskView;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\CurrentExecutor;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements Query<?CurrentTaskView>
 */
#[ExecutedBy(CurrentExecutor::class), APIQuery('tasks', 'current')]
final class Current implements Query
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        #[HydrateFromSession('userId')]
        public UserId $userId
    ) {
    }
}
