<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Business\AssigneeNotProvided;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\User\Business\UserId;

final class BacklogItemTest extends TestCase
{
    public function testCanBeStarted(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $item = new BacklogItem($description, null, null, new ArrayCollection());

        $assigneeId = UserId::generate();

        $result = $item->toStarted($assigneeId, new \Safe\DateTimeImmutable());

        self::assertEquals($description, $result->description());
        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testCanBeStartedWithPresetAssignee(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $assigneeId = UserId::generate();
        $item = new BacklogItem($description, $assigneeId, null, new ArrayCollection());

        $result = $item->toStarted(null, new \Safe\DateTimeImmutable());

        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testPrioritisesNewlyPassedAssigneeId(): void
    {

        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $item = new BacklogItem($description, UserId::generate(), null, new ArrayCollection());

        $assigneeId = UserId::generate();

        $result = $item->toStarted($assigneeId, new \Safe\DateTimeImmutable());

        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testThrowsIfNoAssigneeIsSetAndNoneIsProvided(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $item = new BacklogItem($description, null, null, new ArrayCollection());

        $this->expectException(AssigneeNotProvided::class);
        $item->toStarted(null, new \Safe\DateTimeImmutable());
    }

    public function testStartsRecordingTimeWhenStarted(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection());
        $item = new BacklogItem($description, null, null, new ArrayCollection());
        $now = new \Safe\DateTimeImmutable();
        $started = $item->toStarted(UserId::generate(), $now);

        self::assertEquals([new TimeRecord($now)], $started->timeRecords()->toArray());
    }
}
