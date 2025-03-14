<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final readonly class Done implements Task
{
    public function __construct(
        private TaskDescription $description,
        private UserId $assigneeId,
        /**
         * @var ArrayCollection<int,TimeRecord>
         */
        private ArrayCollection $timeRecords
    ) {

    }

    public function toIdea(DateTimeImmutable $now): Idea
    {
        return new Idea($this->description); // TODO is this actually the behaviour we want? or should it be disallowed?
    }

    public function id(): TaskId
    {
        return $this->description->id();
    }

    public function title(): string
    {
        return $this->description->title();
    }

    public function assigneeId(): UserId
    {
        return $this->assigneeId;
    }

    public function tags(): ArrayCollection
    {
        return $this->description->tags();
    }

    public function deadline(): ?DateTimeImmutable
    {
        return null; // TODO: should we keep it so we have history???
    }

    public function timeRecords(): ArrayCollection
    {
        return $this->timeRecords;
    }
}
