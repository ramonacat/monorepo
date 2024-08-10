<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\HttpApi;

use Ramona\Ras2\Task\Business\TaskId;

final readonly class StartWorkRequest
{
    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public TaskId $taskId
    ) {
    }
}
