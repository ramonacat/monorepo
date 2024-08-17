<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\Random;
use Ramona\Ras2\Task\Application\TaskView;

/**
 * @implements Executor<ArrayCollection<int, TaskView>, Random>
 */
final class RandomExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        /** @var list<array{id:string, title:string, assignee_name:string, tags:?string, deadline: ?string, time_records: string}> $rawTasks */
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
                    deadline,
                    time_records
                FROM tasks t
                LEFT JOIN users u ON u.id = t.assignee_id
                WHERE 
                    deadline IS NULL 
                    AND state = \'BACKLOG_ITEM\'
                ORDER BY random()
                LIMIT :limit
            ', [
                'limit' => $query->limit,
            ]);

        return (new ArrayCollection($rawTasks))
            ->map(function (array $rawTask) {
                $rawTask['tags'] = \Safe\json_decode($rawTask['tags'] ?? '[]', true);
                $rawTask['time_records'] = \Safe\json_decode($rawTask['time_records'], true);
                return $rawTask;
            })
            ->map(fn (array $raw) => $this->hydrator->hydrate(TaskView::class, $raw));
    }
}
