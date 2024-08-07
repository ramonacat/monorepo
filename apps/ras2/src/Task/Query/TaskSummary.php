<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Query;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\UserId;

/**
 * @psalm-suppress PossiblyUnusedProperty
 */
final readonly class TaskSummary
{
    /**
     * @param ArrayCollection<int, string> $tags
     */
    public function __construct(
        public TaskId $id,
        public string $title,
        public ?UserId $assignee,
        public ArrayCollection $tags,
        public string $state
    ) {
    }
}
