<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\Task\Query\Query;
use Ramona\Ras2\Task\Query\TaskSummary;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\UserId;

/**
 * @psalm-suppress UnusedClass
 * @implements Executor<ArrayCollection<int, TaskSummary>>
 */
class AllTasksExecutor implements Executor
{
    private Connection $connection;

    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    public function execute(Query $query): object
    {
        $allTasks = $this
            ->connection
            ->prepare('
                SELECT *, 
                    (
                        SELECT json_agg(name) 
                        FROM tags 
                            INNER JOIN tasks_tags tt on tags.id = tt.tag_id 
                        WHERE tt.task_id = t.id 
                    ) AS tag_names
                FROM tasks t
            ')
            ->executeQuery()
            ->fetchAllAssociative();

        /** @var ArrayCollection<int, TaskSummary> $result */
        $result = new ArrayCollection();

        foreach ($allTasks as $rawTask) {
            /** @var ArrayCollection<int, string> $tagNames */
            $tagNames = new ArrayCollection(
                $rawTask['tag_names'] !== null
                    ? array_values(array_map(
                        fn ($x) => (string) $x,
                        (array) \Safe\json_decode((string) $rawTask['tag_names'], true)
                    ))
                    : []
            );
            $result->add(new TaskSummary(
                TaskId::fromString((string) $rawTask['id']),
                (string) $rawTask['title'],
                $rawTask['assignee_id'] === null ? null : UserId::fromString((string) $rawTask['assignee_id']),
                $tagNames,
                (string) $rawTask['state']
            ));
        }

        return $result;
    }
}
