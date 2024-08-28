<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\UpsertUserProfileExecutor;
use Ramona\Ras2\User\Business\UserId;

#[ExecutedBy(UpsertUserProfileExecutor::class)]
final readonly class UpsertUserProfile implements Command
{
    /**
     * @param ArrayCollection<int, string> $watchedTags
     */
    public function __construct(
        public UserId $userId,
        #[KeyType('integer')]
        #[ValueType('string')]
        public ArrayCollection $watchedTags
    ) {
    }
}
