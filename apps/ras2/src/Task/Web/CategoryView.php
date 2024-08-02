<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Web;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\CategoryId;

final class CategoryView
{
    /**
     * @param ArrayCollection<int, TaskCardView> $tasks
     */
    public function __construct(
        private CategoryId $categoryId,
        private ArrayCollection $tasks
    ) {
    }

    public function __toString(): string
    {
        $tasks = implode(PHP_EOL, $this->tasks->toArray());

        return <<<EOF
            <div>
                <h1>{$this->categoryId}</h1>
                {$tasks}
            </div>
        EOF;
    }
}
