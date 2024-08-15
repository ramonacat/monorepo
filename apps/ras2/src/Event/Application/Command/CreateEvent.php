<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\User\Business\UserId;

final readonly class CreateEvent implements Command
{
    /**
     * @param ArrayCollection<int, UserId> $attendees
     */
    public function __construct(
        public EventId $id,
        public string $title,
        public \Safe\DateTimeImmutable $startTime,
        public \Safe\DateTimeImmutable $endTime,
        public ArrayCollection $attendees,
    ) {
    }
}
