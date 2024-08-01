<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Ramona\Ras2\UserId;

final class BacklogItem implements Task
{
    private TaskDescription $description;

    private ?UserId $assignee;

    public function __construct(
        TaskDescription $description,
        ?UserId $assigneeId
    ) {
        $this->description = $description;
        $this->assignee = $assigneeId;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function start(?UserId $assignee): Started
    {
        $assignee = $assignee ?? $this->assignee ?? throw AssigneeNotProvided::forTask($this->description->id());

        return new Started($this->description, $assignee);
    }
}
