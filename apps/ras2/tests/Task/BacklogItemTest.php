<?php

declare(strict_types=1);

namespace Task;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\AssigneeNotProvided;
use Ramona\Ras2\Task\BacklogItem;
use Ramona\Ras2\Task\TaskDescription;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\UserId;

final class BacklogItemTest extends TestCase
{
    public function testCanBeStarted(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $item = new BacklogItem($description, null);

        $assigneeId = UserId::generate();

        $result = $item->start($assigneeId);

        self::assertEquals($description, $result->description());
        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testCanBeStartedWithPresetAssignee(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $assigneeId = UserId::generate();
        $item = new BacklogItem($description, $assigneeId);

        $result = $item->start(null);

        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testPrioritisesNewlyPassedAssigneeId(): void
    {

        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $item = new BacklogItem($description, UserId::generate());

        $assigneeId = UserId::generate();

        $result = $item->start($assigneeId);

        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testThrowsIfNoAssigneeIsSetAndNoneIsProvided(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $item = new BacklogItem($description, null);

        $this->expectException(AssigneeNotProvided::class);
        $item->start(null);
    }
}
