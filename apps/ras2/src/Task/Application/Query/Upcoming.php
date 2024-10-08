<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\UpcomingExecutor;
use Ramona\Ras2\User\Business\UserId;

/**
 * @implements Query<ArrayCollection<int, TaskView>>
 */
#[ExecutedBy(UpcomingExecutor::class), APIQuery('tasks', 'upcoming')]
final class Upcoming implements Query
{
    public function __construct(
        public int $limit,
        public ?UserId $assigneeId
    ) {
    }
}
