<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final class BacklogItem implements Task
{
    public function __construct(
        private TaskDescription $description,
        private ?UserId $assigneeId,
        private ?DateTimeImmutable $deadline,
        /**
         * @var ArrayCollection<int,TimeRecord>
         */
        private ArrayCollection $timeRecords
    ) {
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function toStarted(?UserId $assignee, DateTimeImmutable $now): Started
    {
        $assignee = $assignee ?? $this->assigneeId ?? throw AssigneeNotProvided::forTask($this->description->id());

        $started = new Started($this->description, $assignee, $this->deadline, $this->timeRecords);
        $started->startRecordingTime($now);

        return $started;
    }

    public function toDone(UserId $userId): Done
    {
        return new Done($this->description(), $userId, $this->timeRecords);
    }

    public function toIdea(DateTimeImmutable $now): Idea
    {
        return new Idea($this->description); // TODO: do we want to keep time records?
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

    public function timeRecords(): ArrayCollection
    {
        return $this->timeRecords;
    }
}
