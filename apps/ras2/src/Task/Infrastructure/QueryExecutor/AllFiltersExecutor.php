<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\FilterView;
use Ramona\Ras2\Task\Application\Query\AllFilters;

/**
 * @implements Executor<ArrayCollection<int, FilterView>, AllFilters>
 */
final class AllFiltersExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        $raw = $this->connection->fetchAllAssociative('
            SELECT id, name FROM tasks_filters
        ');

        return (new ArrayCollection($raw))
            ->map(fn ($row) => $this->hydrator->hydrate(FilterView::class, $row));
    }
}
