<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APIQuery;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\QueryExecutor\ByIdExecutor;

/**
 * @implements Query<?TaskView>
 */
#[ExecutedBy(ByIdExecutor::class), APIQuery('tasks/{id:uuid}', 'by-id')]
final readonly class ById implements Query
{
    public function __construct(
        public TaskId $id
    ) {
    }
}
