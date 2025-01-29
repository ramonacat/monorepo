<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Doctrine\DBAL\Connection;
use Mustache_Engine;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Executor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\Hydrator;
use Ramona\Ras2\Task\Application\Query\ById;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Infrastructure\NotFound;

/**
 * @implements Executor<TaskView, ById>
 */
final readonly class ByIdExecutor implements Executor
{
    public function __construct(
        private Connection $connection,
        private Hydrator $hydrator,
        private Mustache_Engine $mustache
    ) {
    }

    public function execute(Query $query): mixed
    {
        $rawTask = $this
            ->connection
            ->fetchAssociative(
                $this->mustache->render('tasks.sql.mustache', [
                    'where' => 't.id = :task_id',
                ]),
                [
                    'task_id' => $query->id,
                ]
            );
        if ($rawTask === false) {
            throw NotFound::forId($query->id);
        }

        return $this->hydrator->hydrate(TaskView::class, TaskFormatter::prepareForHydration($rawTask));
    }
}
