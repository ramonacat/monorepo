<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\CQRS\Command\Command;
use Ramona\Ras2\Task\TagId;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\UserId;

final readonly class CreateBacklogItem implements Command
{
    /**
     * @param ArrayCollection<int, TagId> $tags
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public TaskId $id,
        public string $title,
        public ArrayCollection $tags,
        public ?UserId $assignee
    ) {
    }
}
