<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\Current;
use Ramona\Ras2\Task\Application\TaskView;

/**
 * @implements Executor<?TaskView, Current>
 */
final class CurrentExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        $results = $this->connection->fetchAllAssociative('
            SELECT 
                    t.id, 
                    title, 
                    u.name as assignee_name,
                    (
                        SELECT 
                            json_agg(ta.name) 
                        FROM tags ta 
                            INNER JOIN tasks_tags tt ON ta.id = tt.tag_id 
                        WHERE tt.task_id = t.id
                    ) AS tags, 
                    deadline,
                    time_records
                FROM tasks t
                LEFT JOIN users u ON u.id = t.assignee_id
                WHERE u.id=:user_id AND t.state = \'STARTED\'
        ', [
            'user_id' => $query->userId,
        ]);

        $rowCount = count($results);

        if ($rowCount === 0) {
            return null;
        }

        $results[0]['tags'] = \Safe\json_decode($results[0]['tags'], true);
        $results[0]['time_records'] = \Safe\json_decode($results[0]['time_records'], true);

        return $this->hydrator->hydrate(TaskView::class, $results[0]);
    }
}
