<?php

declare(strict_types=1);

namespace Ramona\Ras2\User\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\User\Application\Query\All;
use Ramona\Ras2\User\Application\UserView;

/**
 * @implements Executor<ArrayCollection<int, UserView>, All>
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
        $results = $this->connection->fetchAllAssociative('
            SELECT id, name as username FROM users WHERE is_system = 0::bit
        ');

        return (new ArrayCollection($results))
            ->map(fn ($x) => $this->hydrator->hydrate(UserView::class, $x));
    }
}
