<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

use Doctrine\Common\Collections\ArrayCollection;

final class TaskListView
{
    /**
     * @param ArrayCollection<int, CategoryView> $tasks
     */
    public function __construct(
        private ArrayCollection $tasks
    ) {

    }

    public function __toString(): string
    {
        return implode(' ', $this->tasks->toArray());
    }
}
