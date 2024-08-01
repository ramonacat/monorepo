<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramona\Ras2\UserId;

/**
 * @psalm-suppress UnusedClass
 */
class Done implements Task
{
    /**
     * @phpstan-ignore property.onlyWritten
     */
    private TaskDescription $description;

    /**
     * @phpstan-ignore property.onlyWritten
     */
    private UserId $assignee;

    public function __construct(TaskDescription $description, UserId $assignee)
    {

        $this->description = $description;
        $this->assignee = $assignee;
    }
}
