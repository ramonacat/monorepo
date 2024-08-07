<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\UserId;
use Safe\DateTimeImmutable;

final class BacklogItem implements Task
{
    public function __construct(
        private TaskDescription $description,
        private ?UserId $assigneeId,
        private ?DateTimeImmutable $deadline
    ) {
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function start(?UserId $assignee): Started
    {
        $assignee = $assignee ?? $this->assigneeId ?? throw AssigneeNotProvided::forTask($this->description->id());

        return new Started($this->description, $assignee, $this->deadline);
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function description(): TaskDescription
    {
        return $this->description;
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
        return $this->assigneeId;
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }

    public function deadline(): ?DateTimeImmutable
    {
        return $this->deadline;
    }
}
