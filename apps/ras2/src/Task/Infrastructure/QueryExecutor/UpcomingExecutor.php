<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\Upcoming;
use Ramona\Ras2\Task\Application\TaskView;

/**
 * @implements Executor<ArrayCollection<int, TaskView>, Upcoming>
 */
final class UpcomingExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): ArrayCollection
    {
        $rawTasks = $this
            ->connection
            ->fetchAllAssociative('
                SELECT 
                    t.id, 
                    title, 
                    u.name as assignee_name,
                    u.id as assignee_id,
                    (
                        SELECT 
                            json_agg(ta.name) 
                        FROM tags ta 
                            INNER JOIN tasks_tags tt ON ta.id = tt.tag_id 
                        WHERE tt.task_id = t.id
                    ) AS tags, 
                    (deadline).datetime as deadline_timestamp,
                    (deadline).timezone as deadline_timezone,
                    time_records,
                    state as status
                FROM tasks t
                LEFT JOIN users u ON u.id = t.assignee_id
                WHERE 
                    deadline IS NOT NULL 
                    AND state = \'BACKLOG_ITEM\'
                    AND (assignee_id IS NULL OR assignee_id=:assignee_id)
                ORDER BY deadline ASC
                LIMIT :limit
            ', [
                'limit' => $query->limit,
                'assignee_id' => $query->assigneeId,
            ]);

        return (new ArrayCollection($rawTasks))
            ->map(function (array $rawTask) {
                $rawTask['tags'] = \Safe\json_decode($rawTask['tags'] ?? '[]', true);
                $rawTask['timeRecords'] = \Safe\json_decode($rawTask['time_records'], true);
                $rawTask['assigneeId'] = $rawTask['assignee_id'];
                $rawTask['assigneeName'] = $rawTask['assignee_name'];
                $rawTask['deadline'] = [
                    'timestamp' => $rawTask['deadline_timestamp'],
                    'timezone' => $rawTask['deadline_timezone'],
                ];

                return $rawTask;
            })
            ->map(fn (array $raw) => $this->hydrator->hydrate(TaskView::class, $raw));
    }
}
