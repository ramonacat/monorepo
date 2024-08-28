<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\Task\Business\TaskId;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertBacklogItemExecutor;
use Ramona\Ras2\User\Business\UserId;
use Safe\DateTimeImmutable;

#[ExecutedBy(UpsertBacklogItemExecutor::class), APICommand('tasks', 'upsert:backlog-item')]
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
