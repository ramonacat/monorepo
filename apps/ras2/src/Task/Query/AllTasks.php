<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\CQRS\Query\Query;

/**
 * @psalm-suppress UnusedClass
 * @implements Query<ArrayCollection<int, TaskSummary>>
 */
final class AllTasks implements Query
{
}
