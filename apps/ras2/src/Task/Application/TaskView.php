<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Business\TimeRecord;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

/**
 * @psalm-suppress PossiblyUnusedProperty
 */
final readonly class TaskView
{
    /**
     * @param ArrayCollection<int,string> $tags
     * @param ArrayCollection<int,TimeRecord> $timeRecords
     */
    public function __construct(
        public TaskId $id,
        public Status $status,
        public string $title,
        public ?UserId $assigneeId,
        public ?string $assigneeName,
        #[KeyType('integer')]
        #[ValueType('string')]
        public ArrayCollection $tags,
        public ?DateTimeImmutable $deadline,
        #[KeyType('integer')]
        #[ValueType(TimeRecord::class)]
        public ArrayCollection $timeRecords
    ) {
    }
}
