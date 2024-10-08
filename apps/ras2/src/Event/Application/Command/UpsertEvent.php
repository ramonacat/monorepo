<?php

declare(strict_types=1);

namespace Ramona\Ras2\Event\Application\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\Event\Business\EventId;
use Ramona\Ras2\Event\Infrastructure\CommandExecutor\UpsertEventExecutor;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\User\Business\UserId;

#[ExecutedBy(UpsertEventExecutor::class), APICommand('events', 'upsert')]
final readonly class UpsertEvent implements Command
{
    /**
     * @param ArrayCollection<int, UserId> $attendees
     */
    public function __construct(
        public EventId $id,
        public string $title,
        public \Safe\DateTimeImmutable $startTime,
        public \Safe\DateTimeImmutable $endTime,
        #[KeyType('integer')]
        #[ValueType(UserId::class)]
        public ArrayCollection $attendees,
    ) {
    }
}
