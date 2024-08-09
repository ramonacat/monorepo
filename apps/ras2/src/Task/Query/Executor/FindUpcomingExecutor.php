<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Query\FindUpcoming;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\Task\TaskView;

/**
 * @implements Executor<ArrayCollection<int, TaskView>, FindUpcoming>
 */
final class FindUpcomingExecutor implements Executor
{
    public function __construct(
        private Connection $connection
    ) {
    }

    public function execute(Query $query): ArrayCollection
    {
        /** @var list<array{id:string, title:string, assignee_name:?string, tags:string, deadline: ?string}> $rawTasks */
        $rawTasks = $this
            ->connection
            ->fetchAllAssociative('
                SELECT 
                    t.id, 
                    title, 
                    u.name AS assignee_name, 
                    (SELECT json_agg(ta.name) FROM tags ta INNER JOIN tasks_tags tt on ta.id = tt.tag_id WHERE tt.task_id = t.id) AS tags, 
                    deadline
                FROM tasks t
                LEFT JOIN users u ON u.id = t.assignee_id
                WHERE 
                    deadline IS NOT NULL 
                    AND state = \'BACKLOG_ITEM\'
                ORDER BY deadline DESC
            ');
        /** @var array<int, TaskView> $result */
        $result = [];

        foreach ($rawTasks as $task) {
            /** @var array<int, string> $tags */
            $tags = \Safe\json_decode($task['tags']);
            $result[] = new TaskView(
                TaskId::fromString($task['id']),
                $task['title'],
                $task['assignee_name'],
                new ArrayCollection($tags),
                $task['deadline'] === null ? null : \Safe\DateTimeImmutable::createFromFormat(
                    'Y-m-d H:i:sP',
                    $task['deadline']
                )
            );
        }

        return new ArrayCollection($result);
    }
}
