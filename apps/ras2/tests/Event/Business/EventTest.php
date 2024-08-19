<?php

declare(strict_types=1);

namespace Tests\Ramona\Ras2\Event\Business;

use Doctrine\Common\Collections\ArrayCollection;
use PHPUnit\Framework\TestCase;
use Ramona\Ras2\Event\Business\Event;
use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\User\Business\UserId;

final class EventTest extends TestCase
{
    public function testGetId(): void
    {
        $id = EventId::generate();
        $event = new Event(
            $id,
            'This is some title',
            new \Safe\DateTimeImmutable(),
            new \Safe\DateTimeImmutable(),
            new ArrayCollection()
        );

        self::assertEquals($id, $event->id());
    }

    public function testGetTitle(): void
    {
        $event = new Event(
            EventId::generate(),
            'This is some title',
            new \Safe\DateTimeImmutable(),
            new \Safe\DateTimeImmutable(),
            new ArrayCollection()
        );

        self::assertEquals('This is some title', $event->title());
    }

    public function testStart(): void
    {
        $start = new \Safe\DateTimeImmutable();
        $event = new Event(
            EventId::generate(),
            'This is some title',
            $start,
            new \Safe\DateTimeImmutable(),
            new ArrayCollection()
        );

        self::assertEquals($start, $event->start());
    }

    public function testEnd(): void
    {
        $end = new \Safe\DateTimeImmutable();
        $event = new Event(
            EventId::generate(),
            'This is some title',
            new \Safe\DateTimeImmutable(),
            $end,
            new ArrayCollection()
        );

        self::assertEquals($end, $event->end());
    }

    public function testAttendees(): void
    {
        $attendees = new ArrayCollection([UserId::generate(), UserId::generate()]);

        $event = new Event(
            EventId::generate(),
            'This is some title',
            new \Safe\DateTimeImmutable(),
            new \Safe\DateTimeImmutable(),
            $attendees
        );

        self::assertEquals($attendees, $event->attendees());
    }
}
