<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\FilterId;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\ByFilterExecutor;

/**
 * @implements Query<ArrayCollection<int, TaskView>>
 */
#[ExecutedBy(ByFilterExecutor::class), APIQuery('tasks', 'by-filter')]
final readonly class ByFilter implements Query
{
    public function __construct(
        public FilterId $id
    ) {
    }
}
