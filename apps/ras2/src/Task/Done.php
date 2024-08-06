<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\UserId;

/**
 * @psalm-suppress UnusedClass
 */
class Done implements Task
{
    private TaskDescription $description;

    private UserId $assignee;

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(TaskDescription $description, UserId $assignee)
    {

        $this->description = $description;
        $this->assignee = $assignee;
    }

    public function id(): TaskId
    {
        return $this->description->id();
    }

    public function title(): string
    {
        return $this->description->title();
    }

    public function assigneeId(): ?UserId
    {
        return $this->assignee;
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }
}
