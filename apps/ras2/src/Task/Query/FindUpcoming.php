<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\TaskView;
use Ramona\Ras2\User\UserId;

/**
 * @implements Query<ArrayCollection<int, TaskView>>
 */
final class FindUpcoming implements Query
{
    public function __construct(
        public int $limit,
        public ?UserId $assigneeId
    ) {
    }
}
