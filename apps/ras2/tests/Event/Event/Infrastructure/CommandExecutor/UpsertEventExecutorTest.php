<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Event\Event\Infrastructure\CommandExecutor;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Event\Application\Command\UpsertEvent;
use Ramona\Ras2\Event\Business\Event;
use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\Event\Infrastructure\CommandExecutor\UpsertEventExecutor;
use Ramona\Ras2\Event\Infrastructure\Repository;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

final class UpsertEventExecutorTest extends TestCase
{
    public function testWillSaveTheEvent(): void
    {
        $command = new UpsertEvent(
            EventId::generate(),
            'This is a title',
            new DateTimeImmutable(),
            new DateTimeImmutable(),
            new ArrayCollection([UserId::generate(), UserId::generate()])
        );

        $repository = $this->createMock(Repository::class);
        $repository->expects(self::once())->method('save')->with(
            new Event($command->id, $command->title, $command->startTime, $command->endTime, $command->attendees)
        );
        $executor = new UpsertEventExecutor($repository);

        $executor->execute($command);
    }
}
