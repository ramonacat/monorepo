<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Application\UserProfileView;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements Query<UserProfileView>
 */
final readonly class UserProfileByUserId implements Query
{
    public function __construct(
        public UserId $userId
    ) {
    }
}
