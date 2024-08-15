<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;

final class EventView
{
    /**
     * @param ArrayCollection<int, string> $attendeeUsernames
     */
    public function __construct(
        public EventId $id,
        public string $title,
        public \Safe\DateTimeImmutable $start,
        public \Safe\DateTimeImmutable $end,
        #[KeyType('integer')]
        #[ValueType('string')]
        public ArrayCollection $attendeeUsernames
    ) {
    }
}
