<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Query;

use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\Application\TaskView;
use Ramona\Ras2\Task\Business\TaskId;

/**
 * @implements Query<?TaskView>
 */
final readonly class ById implements Query
{
    public function __construct(
        public TaskId $taskId
    ) {
    }
}
