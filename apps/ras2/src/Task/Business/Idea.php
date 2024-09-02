<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final readonly class Idea implements Task
{
    public function __construct(
        private TaskDescription $description
    ) {
    }

    public function toBacklog(?UserId $assignee): BacklogItem
    {
        return new BacklogItem($this->description, $assignee, null, new ArrayCollection());
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

    public function deadline(): ?DateTimeImmutable
    {
        return null;
    }

    public function timeRecords(): ArrayCollection
    {
        return new ArrayCollection();
    }

    public function toIdea(DateTimeImmutable $now): self
    {
        return $this;
    }
}
