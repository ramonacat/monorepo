<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Business\NoRunningTimer;
use Ramona\Ras2\Task\Business\PreviousTimerStillRunning;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\User\Business\UserId;

final class StartedTest extends TestCase
{
    public function testWillThrowIfTryingToStartAlreadyStarted(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $record = new TimeRecord(new \Safe\DateTimeImmutable());
        $started = new Started($description, UserId::generate(), null, new ArrayCollection([$record]));

        $this->expectException(PreviousTimerStillRunning::class);
        $this->expectExceptionMessage('Previous timer is still running');
        $started->startRecordingTime(new \Safe\DateTimeImmutable());
    }

    public function testWillStopRunningTimer(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $startTime = new \Safe\DateTimeImmutable();
        $record = new TimeRecord($startTime);
        $started = new Started($description, UserId::generate(), null, new ArrayCollection([$record]));

        $endTime = new \Safe\DateTimeImmutable();
        $started->stopRecordingTime($endTime);

        self::assertEquals([new TimeRecord($startTime, $endTime)], $started->timeRecords()->toArray());
    }

    public function testWillThrowOnStopIfThereIsNoTimer(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $started = new Started($description, UserId::generate(), null, new ArrayCollection());

        $this->expectException(NoRunningTimer::class);
        $this->expectExceptionMessage('There is no currently running timer');
        $started->stopRecordingTime(new \Safe\DateTimeImmutable());
    }

    public function testCanBeMovedToBacklog(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $startTime = new \Safe\DateTimeImmutable();
        $record = new TimeRecord($startTime);
        $started = new Started($description, UserId::generate(), null, new ArrayCollection([$record]));

        $endTime = new \Safe\DateTimeImmutable();
        $backlog = $started->toBacklog($endTime);

        self::assertEquals([new TimeRecord($startTime, $endTime)], $backlog->timeRecords()->toArray());
    }
}
