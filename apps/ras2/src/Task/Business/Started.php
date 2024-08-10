<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final class Started implements Task
{
    public function __construct(
        private TaskDescription $description,
        private UserId $assigneeId,
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
    public function description(): TaskDescription
    {
        return $this->description;
    }

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function assigneeId(): UserId
    {
        return $this->assigneeId;
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

    /**
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function deadline(): ?DateTimeImmutable
    {
        return $this->deadline;
    }

    public function timeRecords(): ArrayCollection
    {
        return $this->timeRecords;
    }

    public function startRecordingTime(\Safe\DateTimeImmutable $now): void
    {
        $last = $this->timeRecords->last();

        if ($last !== false && $last->ended() === null) {
            throw PreviousTimerStillRunning::create();
        }

        $this->timeRecords->add(new TimeRecord($now));
    }

    public function stopRecordingTime(\Safe\DateTimeImmutable $now): void
    {
        $last = $this->timeRecords->last();

        if ($last === false || $last->ended() !== null) {
            throw NoRunningTimer::create();
        }

        $last->finish($now);
    }

    public function toBacklog(\Safe\DateTimeImmutable $now): BacklogItem
    {
        $lastTimeRecord = $this->timeRecords->last();
        if ($lastTimeRecord !== false) {
            $lastTimeRecord->finish($now);
        }

        return new BacklogItem($this->description, $this->assigneeId, $this->deadline, $this->timeRecords);
    }
}
