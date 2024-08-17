<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\ById;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Infrastructure\NotFound;

/**
 * @implements Executor<?TaskView, ById>
 */
final readonly class ByIdExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        /** @var array{id:string, title:string, assignee_name:string, tags:string, deadline: ?string, time_records: string}|false $rawTask */
        $rawTask = $this
            ->connection
            ->fetchAssociative('
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
                    t.id = :task_id
            ', [
                'task_id' => $query->taskId,
            ]);
        if ($rawTask === false) {
            throw NotFound::forId($query->taskId);
        }

        $rawTask['tags'] = \Safe\json_decode($rawTask['tags'], true);
        $rawTask['time_records'] = \Safe\json_decode($rawTask['time_records'], true);

        return $this->hydrator->hydrate(TaskView::class, $rawTask);
    }
}
