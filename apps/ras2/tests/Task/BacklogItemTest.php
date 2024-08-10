<?php

declare(strict_types=1);

namespace Task;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Business\AssigneeNotProvided;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\User\Business\UserId;

final class BacklogItemTest extends TestCase
{
    public function testCanBeStarted(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $item = new BacklogItem($description, null, null);

        $assigneeId = UserId::generate();

        $result = $item->start($assigneeId);

        self::assertEquals($description, $result->description());
        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testCanBeStartedWithPresetAssignee(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $assigneeId = UserId::generate();
        $item = new BacklogItem($description, $assigneeId, null);

        $result = $item->start(null);

        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testPrioritisesNewlyPassedAssigneeId(): void
    {

        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $item = new BacklogItem($description, UserId::generate(), null);

        $assigneeId = UserId::generate();

        $result = $item->start($assigneeId);

        self::assertEquals($assigneeId, $result->assigneeId());
    }

    public function testThrowsIfNoAssigneeIsSetAndNoneIsProvided(): void
    {
        $description = new TaskDescription(TaskId::generate(), 'title', new ArrayCollection([]));
        $item = new BacklogItem($description, null, null);

        $this->expectException(AssigneeNotProvided::class);
        $item->start(null);
    }
}
