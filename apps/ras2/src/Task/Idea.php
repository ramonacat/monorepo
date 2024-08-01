<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramona\Ras2\UserId;

class Idea implements Task
{
    private TaskDescription $description;

    public function __construct(TaskDescription $description)
    {
        $this->description = $description;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function toBacklog(?UserId $assignee): BacklogItem
    {
        return new BacklogItem($this->description, $assignee);
    }
}
