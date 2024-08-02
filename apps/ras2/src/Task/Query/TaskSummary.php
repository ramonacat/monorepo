<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\CategoryId;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\UserId;

final readonly class TaskSummary
{
    /**
     * @psalm-suppress UnusedProperty
     */
    public TaskId $id;

    /**
     * @psalm-suppress UnusedProperty
     */
    public CategoryId $categoryId;

    /**
     * @psalm-suppress UnusedProperty
     */
    public string $title;

    /**
     * @psalm-suppress UnusedProperty
     */
    public ?UserId $assignee;

    /**
     * @psalm-suppress UnusedProperty
     * @var ArrayCollection<int, string>
     */
    public ArrayCollection $tags;

    /**
     * @psalm-suppress UnusedProperty
     */
    public string $state;

    /**
     * @param ArrayCollection<int, string> $tags
     */
    public function __construct(TaskId $id, CategoryId $categoryId, string $title, ?UserId $assignee, ArrayCollection $tags, string $state)
    {
        $this->id = $id;
        $this->categoryId = $categoryId;
        $this->title = $title;
        $this->assignee = $assignee;
        $this->tags = $tags;
        $this->state = $state;
    }
}
