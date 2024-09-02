<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;

final readonly class TaskDescription
{
    /**
     * @param ArrayCollection<int, TagId> $tags
     */
    public function __construct(
        private TaskId $id,
        private string $title,
        private ArrayCollection $tags
    ) {
    }

    public function id(): TaskId
    {
        return $this->id;
    }

    public function title(): string
    {
        return $this->title;
    }

    /**
     * @return ArrayCollection<int, TagId>
     */
    public function tags(): ArrayCollection
    {
        return $this->tags;
    }
}
