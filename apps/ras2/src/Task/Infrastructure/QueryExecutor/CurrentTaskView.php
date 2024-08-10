<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Infrastructure\QueryExecutor;

use Ramona\Ras2\Task\Business\TaskId;

final readonly class CurrentTaskView
{
    public function __construct(
        public TaskId $id,
        public string $title,
        public \Safe\DateTimeImmutable $startTime,
        public bool $isPaused
    ) {
    }
}
