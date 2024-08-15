<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Application\CurrentTaskView;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Business\TaskId;

/**
 * @implements Executor<?CurrentTaskView, Current>
 */
final class CurrentExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
    ) {
    }

    public function execute(Query $query): mixed
    {
        $results = $this->connection->fetchAllAssociative('
            SELECT 
                    t.id, 
                    t.title,
                    t.time_records
                FROM tasks t
                WHERE t.assignee_id=:user_id AND t.state = \'STARTED\'
        ', [
            'user_id' => $query->userId,
        ]);

        $rowCount = count($results);

        if ($rowCount === 0) {
            return null;
        }

        $timeRecords = new ArrayCollection(\Safe\json_decode($results[0]['time_records'], true));
        $lastRecord = $timeRecords->last();

        if ($lastRecord === false) {
            throw new \RuntimeException('Started task has no time records');
        }

        return new CurrentTaskView(
            TaskId::fromString($results[0]['id']),
            $results[0]['title'],
            \Safe\DateTimeImmutable::createFromFormat(
                'Y-m-d H:i:s',
                $lastRecord['started']['timestamp'],
                new \DateTimeZone($lastRecord['started']['timezone'])
            ),
            $lastRecord['ended'] !== null
        );
    }
}
