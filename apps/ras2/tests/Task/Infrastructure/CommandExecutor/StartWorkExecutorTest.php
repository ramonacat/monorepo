<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\Clock;
use Ramona\Ras2\Task\Application\Command\StartWork;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Idea;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\InvalidTaskState;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\StartWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\User\Business\UserId;

final class StartWorkExecutorTest extends TestCase
{
    public function testWillReturnOtherStartedTasksToBacklog(): void
    {
        $descriptionA = new TaskDescription(
            TaskId::generate(),
            'Title A',
            new ArrayCollection([TagId::generate(), TagId::generate()])
        );
        $descriptionB = new TaskDescription(TaskId::generate(), 'Title B', new ArrayCollection([
            TagId::generate(),
            TagId::generate(),
        ]));
        $descriptionC = new TaskDescription(TaskId::generate(), 'Title B', new ArrayCollection([
            TagId::generate(),
            TagId::generate(),
        ]));

        $assigneeA = UserId::generate();
        $startedA = new Started($descriptionA, $assigneeA, null, new ArrayCollection([]));
        $assigneeB = UserId::generate();
        $startedB = new Started($descriptionB, $assigneeB, null, new ArrayCollection([]));

        $repositoryMock = $this->createMock(Repository::class);
        $repositoryMock
            ->method('findStartedTasks')
            ->willReturn(new ArrayCollection([$startedA, $startedB]));

        $saved = [];
        $repositoryMock
            ->expects(self::exactly(3))
            ->method('save')
            ->willReturnCallback(function ($item) use (&$saved) { $saved[] = $item; });

        $repositoryMock
            ->expects(self::once())
            ->method('getById')
            ->willReturn(new BacklogItem($descriptionC, null, null, new ArrayCollection()));

        $repositoryMock
            ->method('transactional')
            ->willReturnCallback(fn ($x) => ($x)());

        $clockMock = $this->createMock(Clock::class);
        $now = new \Safe\DateTimeImmutable();
        $clockMock
            ->method('now')
            ->willReturn($now);

        $executor = new StartWorkExecutor($repositoryMock, $clockMock);

        $taskId = TaskId::generate();
        $userId = UserId::generate();

        $executor->execute(new StartWork($taskId, $userId));

        self::assertCount(3, $saved);

        /** @var array<int,mixed> $saved */
        self::assertEquals(new BacklogItem($descriptionA, $assigneeA, null, new ArrayCollection()), $saved[0]);
        self::assertEquals(new BacklogItem($descriptionB, $assigneeB, null, new ArrayCollection()), $saved[1]);

        self::assertEquals(
            new Started($descriptionC, $userId, null, new ArrayCollection([new TimeRecord($now)])),
            $saved[2]
        );
    }

    public function testWillWorkWithAStartedTask(): void
    {
        $descriptionA = new TaskDescription(
            TaskId::generate(),
            'Title A',
            new ArrayCollection([TagId::generate(), TagId::generate()])
        );
        $descriptionB = new TaskDescription(TaskId::generate(), 'Title B', new ArrayCollection([
            TagId::generate(),
            TagId::generate(),
        ]));
        $descriptionC = new TaskDescription(TaskId::generate(), 'Title B', new ArrayCollection([
            TagId::generate(),
            TagId::generate(),
        ]));

        $assigneeA = UserId::generate();
        $startedA = new Started($descriptionA, $assigneeA, null, new ArrayCollection([]));
        $assigneeB = UserId::generate();
        $startedB = new Started($descriptionB, $assigneeB, null, new ArrayCollection([]));

        $repositoryMock = $this->createMock(Repository::class);
        $repositoryMock
            ->method('findStartedTasks')
            ->willReturn(new ArrayCollection([$startedA, $startedB]));

        $saved = [];
        $repositoryMock
            ->expects(self::exactly(3))
            ->method('save')
            ->willReturnCallback(function ($item) use (&$saved) { $saved[] = $item; });

        $assigneeC = UserId::generate();

        $repositoryMock
            ->expects(self::once())
            ->method('getById')
            ->willReturn(new Started($descriptionC, $assigneeC, null, new ArrayCollection([])));

        $repositoryMock
            ->method('transactional')
            ->willReturnCallback(fn ($x) => ($x)());

        $clockMock = $this->createMock(Clock::class);
        $now = new \Safe\DateTimeImmutable();
        $later = new \Safe\DateTimeImmutable('+1 hour');
        $clockMock
            ->method('now')
            ->willReturnOnConsecutiveCalls($now, $now, $later);

        $executor = new StartWorkExecutor($repositoryMock, $clockMock);

        $taskId = TaskId::generate();
        $userId = UserId::generate();

        $executor->execute(new StartWork($taskId, $userId));

        self::assertCount(3, $saved);

        /** @var array{0:BacklogItem, 1:BacklogItem, 2:Started} $saved */
        self::assertEquals(new BacklogItem($descriptionA, $assigneeA, null, new ArrayCollection()), $saved[0]);
        self::assertEquals(new BacklogItem($descriptionB, $assigneeB, null, new ArrayCollection()), $saved[1]);

        self::assertEquals(new Started(
            $descriptionC,
            $assigneeC,
            null,
            new ArrayCollection([new TimeRecord($later)])
        ), $saved[2]);
    }

    public function testWillThrowOnInvalidState(): void
    {
        $repositoryMock = $this->createMock(Repository::class);
        $repositoryMock
            ->method('transactional')
            ->willReturnCallback(fn ($x) => ($x)());

        $taskId = TaskId::fromString('01913c1d-9f4a-738d-b361-03ac290f114a');
        $repositoryMock
            ->method('getById')
            ->willReturn(new Idea(new TaskDescription($taskId, 'title', new ArrayCollection())));

        $repositoryMock
            ->method('findStartedTasks')
            ->willReturn(new ArrayCollection());

        $clockMock = $this->createMock(Clock::class);
        $clockMock->method('now')
            ->willReturn(new \Safe\DateTimeImmutable());

        $executor = new StartWorkExecutor($repositoryMock, $clockMock);

        $this->expectException(InvalidTaskState::class);
        $this->expectExceptionMessage(
            'Task 01913c1d-9f4a-738d-b361-03ac290f114a is in unexpected state: Ramona\Ras2\Task\Business\Idea'
        );
        $executor->execute(new StartWork($taskId, UserId::generate()));
    }
}
