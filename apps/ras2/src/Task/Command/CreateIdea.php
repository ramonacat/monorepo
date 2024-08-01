<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\CategoryId;
use Ramona\Ras2\Task\TagId;
use Ramona\Ras2\Task\TaskId;

final readonly class CreateIdea implements Command
{
    public TaskId $id;

    public CategoryId $categoryId;

    public string $title;

    /**
     * @var ArrayCollection<int, TagId>
     */
    public ArrayCollection $tags;

    /**
     * @param ArrayCollection<int, TagId> $tags
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(TaskId $id, CategoryId $categoryId, string $title, ArrayCollection $tags)
    {
        $this->id = $id;
        $this->categoryId = $categoryId;
        $this->title = $title;
        $this->tags = $tags;
    }
}
