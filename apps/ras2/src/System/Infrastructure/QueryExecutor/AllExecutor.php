<?php

declare(strict_types=1);

namespace Ramona\Ras2\System\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\System\Application\Query\All;
use Ramona\Ras2\System\Application\SystemView;

/**
 * @implements Executor<ArrayCollection<int, SystemView>, All>
 */
final class AllExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        $rawResults = $this
            ->connection
            ->fetchAllAssociative('
                SELECT 
                    id, hostname, operating_system 
                FROM systems
            ');

        $rawResults = new ArrayCollection($rawResults);

        return $rawResults
            ->map(function (array $x) {
                $x['operatingSystem'] = \Safe\json_decode($x['operating_system'], true);

                return $x;
            })
            ->map(fn (array $x) => $this->hydrator->hydrate(SystemView::class, $x));
    }
}
