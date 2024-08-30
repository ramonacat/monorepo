<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\Task\Application\FilterView;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\AllFiltersExecutor;

/**
 * @implements Query<ArrayCollection<int,FilterView>>
 */
#[ExecutedBy(AllFiltersExecutor::class), APIQuery('tasks/filters', 'all')]
final class AllFilters implements Query
{
}
