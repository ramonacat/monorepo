<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Query\Query;
use Ramona\Ras2\Task\TaskView;

/**
 * @implements Query<ArrayCollection<int, TaskView>>
 */
final readonly class FindRandom implements Query
{
    public function __construct(
        public int $limit
    ) {
    }
}
