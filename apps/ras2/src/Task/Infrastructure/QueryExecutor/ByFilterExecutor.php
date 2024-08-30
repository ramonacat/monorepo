<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\DBAL\Connection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\ByFilter;
use Ramona\Ras2\Task\Application\TaskView;

/**
 * @implements Executor<ArrayCollection<int, TaskView>, ByFilter>
 */
final readonly class ByFilterExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private \Mustache_Engine $mustache,
        private Hydrator $hydrator
    ) {
    }

    public function execute(Query $query): mixed
    {
        $filter = $this->connection->fetchAssociative(
            'SELECT id, name, assignee_ids, tags_ids FROM tasks_filters WHERE id=:filter_id',
            [
                'filter_id' => $query->id,
            ]
        );
        if ($filter === false) {
            throw new \RuntimeException('Filter not found for ID: ' . $query->id);
        }

        $assigneeIds = \Safe\json_decode($filter['assignee_ids']);
        $tagIds = \Safe\json_decode($filter['tags_ids']);

        $where = '1=1 ' . PHP_EOL;
        $arguments = [];

        if (count($assigneeIds) > 0) {
            $where .= ' AND ?::jsonb @> to_jsonb(assignee_id) ' . PHP_EOL;
            $arguments[] = \Safe\json_encode($assigneeIds);
        }

        if (count($tagIds) > 0) {
            $where .= ' AND EXISTS(SELECT
                    1
                    FROM tags ta
                    INNER JOIN tasks_tags tt ON ta.id = tt.tag_id
                    WHERE tt.task_id = t.id
                    AND ? @> to_jsonb(ta.id)
                ) ' . PHP_EOL;
            $arguments[] = \Safe\json_encode($tagIds);
        }

        $query = $this->mustache->render('tasks.sql.mustache', [
            'where' => $where,
        ]);

        $raw = $this->connection->fetchAllAssociative($query, $arguments);

        return (new ArrayCollection($raw))
            ->map(TaskFormatter::prepareForHydration(...))
            ->map(fn ($x) => $this->hydrator->hydrate(TaskView::class, $x));
    }
}
