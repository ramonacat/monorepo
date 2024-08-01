<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramona\Ras2\UserId;

final class Started implements Task
{
    /**
     * @psalm-suppress UnusedProperty
     * @phpstan-ignore property.onlyWritten
     */
    private TaskDescription $description;

    /**
     * @psalm-suppress UnusedProperty
     * @phpstan-ignore property.onlyWritten
     */
    private UserId $assignee;

    public function __construct(TaskDescription $description, UserId $assignee)
    {
        $this->description = $description;
        $this->assignee = $assignee;
    }
}
