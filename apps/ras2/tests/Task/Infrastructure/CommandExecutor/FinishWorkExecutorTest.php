<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Task\Infrastructure\CommandExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\SharedCore\Infrastructure\ClockInterface;
use Ramona\Ras2\Task\Application\Command\FinishWork;
use Ramona\Ras2\Task\Business\BacklogItem;
use Ramona\Ras2\Task\Business\Done;
use Ramona\Ras2\Task\Business\Started;
use Ramona\Ras2\Task\Business\TagId;
use Ramona\Ras2\Task\Business\TaskDescription;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\FinishWorkExecutor;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\InvalidTaskState;
use Ramona\Ras2\Task\Infrastructure\Repository;
use Ramona\Ras2\User\Business\UserId;

final class FinishWorkExecutorTest extends TestCase
{
    public function testWillSave(): void
    {

        $startTime = new \Safe\DateTimeImmutable();
        $endTime = new \Safe\DateTimeImmutable('+1 hour');
        $taskId = TaskId::generate();
        $task = new Started(
            new TaskDescription($taskId, 'title', new ArrayCollection([TagId::generate(), TagId::generate()])),
            UserId::generate(),
            null,
            new ArrayCollection([new TimeRecord($startTime)])
        );

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
            ->willReturnCallback(function (Done $doneItem) use ($startTime, $endTime) {
                self::assertEquals([new TimeRecord($startTime, $endTime)], $doneItem->timeRecords()->toArray());
            });

        $clockMock = $this->createMock(ClockInterface::class);
        $clockMock->method('now')
            ->willReturn($endTime);

        $executor = new FinishWorkExecutor($repositoryMock, $clockMock);

        $executor->execute(new FinishWork($taskId));
    }

    public function testWillThrowIfTaskIsNotStarted(): void
    {
        $startTime = new \Safe\DateTimeImmutable();
        $endTime = new \Safe\DateTimeImmutable('+1 hour');
        $taskId = TaskId::fromString('01913b63-4817-728e-ad7b-e769dd133af3');
        $task = new BacklogItem(
            new TaskDescription($taskId, 'title', new ArrayCollection([TagId::generate(), TagId::generate()])),
            UserId::generate(),
            null,
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
            "Task 01913b63-4817-728e-ad7b-e769dd133af3 is in unexpected state: Ramona\Ras2\Task\Business\BacklogItem"
        );
        $executor->execute(new FinishWork($taskId));
    }
}
