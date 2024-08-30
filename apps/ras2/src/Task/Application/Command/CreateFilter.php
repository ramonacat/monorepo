<?php

declare(strict_types=1);

namespace Ramona\Ras2\Task\Application\Command;

use Doctrine\Common\Collections\ArrayCollection;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\Command;
use Ramona\Ras2\SharedCore\Infrastructure\CQRS\Command\ExecutedBy;
use Ramona\Ras2\SharedCore\Infrastructure\HTTP\APIDefinition\APICommand;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\KeyType;
use Ramona\Ras2\SharedCore\Infrastructure\Hydration\ValueType;
use Ramona\Ras2\Task\Infrastructure\CommandExecutor\CreateFilterExecutor;
use Ramona\Ras2\User\Business\UserId;

#[ExecutedBy(CreateFilterExecutor::class), APICommand('tasks/filters', 'create-filter')]
final readonly class CreateFilter implements Command
{
    /**
     * @param ArrayCollection<int, UserId> $assignees
     * @param ArrayCollection<int, string> $tags
     */
    public function __construct(
        public string $name,
        #[KeyType('integer'),
            ValueType(UserId::class)]
        public ArrayCollection $assignees,
        #[KeyType('integer'),
            ValueType('string')]
        public ArrayCollection $tags
    ) {

    }
}
