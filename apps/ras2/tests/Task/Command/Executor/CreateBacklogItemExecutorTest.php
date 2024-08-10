<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Command\Executor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Task\Application\Command\UpsertBacklogItem;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertBacklogItemExecutor;
use Ramona\Ras2\User\Business\UserId;
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
            new BacklogItem(
                new TaskDescription($id, 'This is a great idea', new ArrayCollection()),
                $assigneeId,
                null,
                new ArrayCollection()
            ),
        ], $repository->tasks());
    }
}
