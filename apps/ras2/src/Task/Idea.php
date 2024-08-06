<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
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
        return null;
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }
}
