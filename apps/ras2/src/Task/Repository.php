<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

interface Repository
{
    public function save(Task $task): void;
}
