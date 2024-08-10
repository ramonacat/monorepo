<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Business;

use Doctrine\Common\Collections\ArrayCollection;

final class TaskDescription
{
    /**
     * @psalm-suppress UnusedProperty
     */
    private TaskId $id;

    /**
     * @todo this should have a type of "UserText"
     */
    private string $title;

    /**
     * @var ArrayCollection<int, TagId>
     */
    private ArrayCollection $tags;

    /**
     * @param ArrayCollection<int, TagId> $tags
     */
    public function __construct(TaskId $id, string $title, ArrayCollection $tags)
    {
        $this->id = $id;
        $this->title = $title;
        $this->tags = $tags;
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
