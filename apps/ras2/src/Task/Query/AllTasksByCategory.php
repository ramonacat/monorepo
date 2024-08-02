<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @implements Query<ArrayCollection<string, ArrayCollection<int, TaskSummary>>>
 */
final class AllTasksByCategory implements Query
{
}
