<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\UserId;

final class Started implements Task
{
    /**
     * @psalm-suppress UnusedProperty
     */
    private TaskDescription $description;

    /**
     * @psalm-suppress UnusedProperty
     */
    private UserId $assignee;

    public function __construct(TaskDescription $description, UserId $assignee)
    {
        $this->description = $description;
        $this->assignee = $assignee;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function description(): TaskDescription
    {
        return $this->description;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function assigneeId(): UserId
    {
        return $this->assignee;
    }

    public function id(): TaskId
    {
        return $this->description->id();
    }

    public function title(): string
    {
        return $this->description->title();
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }
}
