<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\ClockInterface;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Done;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\Task\Business\Task;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\FinishWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\InvalidTaskState;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\User\Business\UserId;

final class FinishWorkExecutorTest extends TestCase
{
    /**
     * @return iterable<array{0:Task, 1:\Safe\DateTimeImmutable, 2:\Safe\DateTimeImmutable, 3:TimeRecord[]}>
     */
    public static function dataWillSave(): iterable
    {
        $now = new \Safe\DateTimeImmutable();
        $startTime = new \Safe\DateTimeImmutable('-1 hour');
        $taskId = TaskId::generate();
        $startedTask = new Started(
            new TaskDescription($taskId, 'title', new ArrayCollection([TagId::generate(), TagId::generate()])),
            UserId::generate(),
            null,
            new ArrayCollection([new TimeRecord($startTime)])
        );
        yield [$startedTask, $startTime, $now, [new TimeRecord($startTime, $now)]];

        $backlogItem = new BacklogItem(
            new TaskDescription($taskId, 'title', new ArrayCollection([TagId::generate(), TagId::generate()])),
            UserId::generate(),
            null,
            new ArrayCollection(),
        );
        yield [$backlogItem, $startTime, $now, []];
    }

    /**
     * @param TimeRecord[] $expectedTimeRecords
     */
    #[DataProvider('dataWillSave')]
    public function testWillSave(
        Task $task,
        \Safe\DateTimeImmutable $startTime,
        \Safe\DateTimeImmutable $now,
        array $expectedTimeRecords
    ): void {
        $taskId = $task->id();

        $repositoryMock = $this->createMock(Repository::class);
        $repositoryMock
            ->method('getById')
            ->willReturn($task);

        $repositoryMock
            ->method('transactional')
            ->willReturnCallback(fn ($x) => ($x)());

        $repositoryMock
            ->expects(self::once())
            ->method('save')
            ->willReturnCallback(function (Done $doneItem) use ($expectedTimeRecords) {
                self::assertEquals($expectedTimeRecords, $doneItem->timeRecords()->toArray());
            });

        $clockMock = $this->createMock(ClockInterface::class);
        $clockMock->method('now')
            ->willReturn($now);

        $executor = new FinishWorkExecutor($repositoryMock, $clockMock);

        $executor->execute(new FinishWork($taskId, UserId::generate()));
    }

    public function testWillThrowIfTaskIsNotStarted(): void
    {
        $startTime = new \Safe\DateTimeImmutable();
        $endTime = new \Safe\DateTimeImmutable('+1 hour');
        $taskId = TaskId::fromString('01913b63-4817-728e-ad7b-e769dd133af3');
        $task = new Done(
            new TaskDescription($taskId, 'title', new ArrayCollection([TagId::generate(), TagId::generate()])),
            UserId::generate(),
            new ArrayCollection([new TimeRecord($startTime)])
        );

        $repositoryMock = $this->createMock(Repository::class);
        $repositoryMock
            ->method('getById')
            ->willReturn($task);

        $repositoryMock
            ->method('transactional')
            ->willReturnCallback(fn ($x) => ($x)());

        $clockMock = $this->createMock(ClockInterface::class);

        $executor = new FinishWorkExecutor($repositoryMock, $clockMock);

        $this->expectException(InvalidTaskState::class);
        $this->expectExceptionMessage(
            "Task 01913b63-4817-728e-ad7b-e769dd133af3 is in unexpected state: Ramona\Ras2\Task\Business\Done"
        );
        $executor->execute(new FinishWork($taskId, UserId::generate()));
    }
}
