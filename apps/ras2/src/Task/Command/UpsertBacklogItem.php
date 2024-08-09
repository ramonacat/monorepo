<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Serialization\ValueType;
use Ramona\Ras2\Task\TaskId;
use Ramona\Ras2\User\UserId;
use Safe\DateTimeImmutable;

final readonly class UpsertBacklogItem implements Command
{
    /**
     * @param ArrayCollection<int, string> $tags
     * @psalm-suppress PossiblyUnusedMethod
     */
    public function __construct(
        public TaskId $id,
        public string $title,
        #[KeyType('integer'),
            ValueType('string')]
        public ArrayCollection $tags,
        public ?UserId $assignee,
        public ?DateTimeImmutable $deadline
    ) {
    }
}
