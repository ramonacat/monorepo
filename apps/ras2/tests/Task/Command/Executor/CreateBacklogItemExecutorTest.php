<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Command\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\BacklogItem;
use Ramona\Ras2\Task\Command\Executor\UpsertBacklogItemExecutor;
use Ramona\Ras2\Task\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\TaskDescription;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\UserId;
use Tests\Ramona\Ras2\Task\Mocks\MockRepository;

final class CreateBacklogItemExecutorTest extends TestCase
{
    public function testCanCreateAssignedInBacklog(): void
    {
        $repository = new MockRepository();
        $id = TaskId::generate();
        $assigneeId = UserId::generate();
        $executor = new UpsertBacklogItemExecutor($repository);
        $executor->execute(
            new UpsertBacklogItem($id, 'This is a great idea', new ArrayCollection(), $assigneeId, null)
        );

        self::assertEquals([
            new BacklogItem(new TaskDescription($id, 'This is a great idea', new ArrayCollection()), $assigneeId, null),
        ], $repository->tasks());
    }
}
