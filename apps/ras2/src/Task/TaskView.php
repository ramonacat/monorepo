<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task;

use Doctrine\Common\Collections\ArrayCollection;
use Safe\DateTimeImmutable;

/**
 * @psalm-suppress PossiblyUnusedProperty
 */
final readonly class TaskView
{
    /**
     * @param ArrayCollection<int,string> $tags
     */
    public function __construct(
        public TaskId $id,
        public string $title,
        public ?string $assigneeName,
        public ArrayCollection $tags,
        public ?DateTimeImmutable $deadline,
    ) {
    }
}
