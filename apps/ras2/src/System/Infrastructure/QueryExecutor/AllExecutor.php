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
use RuntimeException;

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
                    id, hostname, operating_system, operating_system_type
                FROM systems
            ');

        $rawResults = new ArrayCollection($rawResults);

        return $rawResults
            ->map(function (array $x) {
                $operatingSystem = \Safe\json_decode($x['operating_system'], true);

                switch ($x['operating_system_type']) {
                    case 'NIXOS':
                        $x['isUpToDate'] = $operatingSystem['currentClosure'] === $operatingSystem['latestClosure'];
                        if (! $x['isUpToDate']) {
                            $x['outdatedDescription'] = "current closure: {$operatingSystem['currentClosure']}" . PHP_EOL
                                . "latest closure: {$operatingSystem['latestClosure']}";
                        } else {
                            $x['outdatedDescription'] = '';
                        }
                        break;
                    default:
                        throw new RuntimeException('Unsupported operating system ' . $x['operating_system_type']);
                }

                return $x;
            })
            ->map(fn (array $x) => $this->hydrator->hydrate(SystemView::class, $x));
    }
}
