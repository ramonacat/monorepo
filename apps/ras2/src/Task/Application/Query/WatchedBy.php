<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\HydrateFromSession;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements Query<ArrayCollection<int, TaskView>>
 */
final readonly class WatchedBy implements Query
{
    public function __construct(
        #[HydrateFromSession('userId')]
        public UserId $userId,
        public int $limit
    ) {
    }
}
