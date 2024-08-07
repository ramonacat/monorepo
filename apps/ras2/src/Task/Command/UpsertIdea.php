<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\Task\TaskId;

final readonly class UpsertIdea implements Command
{
    /**
     * @param ArrayCollection<int, string> $tags
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public TaskId $id,
        public string $title,
        public ArrayCollection $tags
    ) {
    }
}
