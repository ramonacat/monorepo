<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Event\Application\EventView;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;

/**
 * @implements Query<ArrayCollection<int, EventView>>
 */
final readonly class InMonth implements Query
{
    public function __construct(
        public int $year,
        public int $month,
        public \DateTimeZone $timeZone
    ) {
    }
}