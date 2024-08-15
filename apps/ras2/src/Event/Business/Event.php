<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Business;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\User\Business\UserId;

final class Event
{
    /**
     * @param ArrayCollection<int, UserId> $attendees
     */
    public function __construct(
        private EventId $id,
        private string $title,
        private \DateTimeImmutable $start,
        private \DateTimeImmutable $end,
        private ArrayCollection $attendees,
    ) {
    }

    public function id(): EventId
    {
        return $this->id;
    }

    public function title(): string
    {
        return $this->title;
    }

    public function start(): \DateTimeImmutable
    {
        return $this->start;
    }

    public function end(): \DateTimeImmutable
    {
        return $this->end;
    }

    /**
     * @return ArrayCollection<int, UserId>
     */
    public function attendees(): ArrayCollection
    {
        return $this->attendees;
    }
}
