<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrateFromSession;
use Ramona\Ras2\Task\Application\UserProfileView;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\UserProfileByUserIdExecutor;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements Query<UserProfileView>
 */
#[ExecutedBy(UserProfileByUserIdExecutor::class), APIQuery('tasks/user-profiles', 'current')]
final readonly class UserProfileByUserId implements Query
{
    public function __construct(
        #[HydrateFromSession('userId')]
        public UserId $userId
    ) {
    }
}
